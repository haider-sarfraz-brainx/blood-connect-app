import 'package:bloc/bloc.dart';
import 'blood_request_events.dart';
import 'blood_request_states.dart';
import '../../data/managers/remote/supabase_service.dart';
import '../../data/models/blood_request_model.dart';

class BloodRequestBloc extends Bloc<BloodRequestEvent, BloodRequestState> {
  final SupabaseService _supabaseService;

  BloodRequestBloc(this._supabaseService) : super(const BloodRequestInitial()) {
    on<CreateBloodRequestEvent>(_onCreateBloodRequest);
    on<GetBloodRequestsEvent>(_onGetBloodRequests);
    on<GetActiveBloodRequestsEvent>(_onGetActiveBloodRequests);
    on<GetAllBloodRequestsEvent>(_onGetAllBloodRequests);
    on<GetBloodRequestsForHomeEvent>(_onGetBloodRequestsForHome);
    on<UpdateBloodRequestStatusEvent>(_onUpdateBloodRequestStatus);
    on<DeleteBloodRequestEvent>(_onDeleteBloodRequest);
    on<AcceptBloodRequestEvent>(_onAcceptBloodRequest);
  }

  Future<void> _onCreateBloodRequest(
    CreateBloodRequestEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        emit(const BloodRequestError('User not authenticated'));
        return;
      }

      final request = BloodRequestModel(
        id: '',
        userId: currentUser.id,
        patientName: event.patientName,
        bloodGroup: event.bloodGroup,
        unitsRequired: event.unitsRequired,
        hospitalName: event.hospitalName,
        hospitalAddress: event.hospitalAddress,
        contactNumber: event.contactNumber,
        status: BloodRequestStatus.pending,
        notes: event.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdRequest = await _supabaseService.insertBloodRequest(request);
      emit(BloodRequestCreated(createdRequest));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onGetBloodRequests(
    GetBloodRequestsEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      final userId = event.userId ?? _supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const BloodRequestError('User not authenticated'));
        return;
      }

      final requests = await _supabaseService.getBloodRequestsByUserId(userId);
      emit(BloodRequestsLoaded(requests));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onGetActiveBloodRequests(
    GetActiveBloodRequestsEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      final requests = await _supabaseService.getActiveBloodRequests(
        bloodGroup: event.bloodGroup,
      );
      emit(BloodRequestsLoaded(requests));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onGetAllBloodRequests(
    GetAllBloodRequestsEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      final requests = await _supabaseService.getAllBloodRequests();
      emit(BloodRequestsLoaded(requests));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onGetBloodRequestsForHome(
    GetBloodRequestsForHomeEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      
      final currentUserId = _supabaseService.client.auth.currentUser?.id;
      final excludeUserId = event.excludeUserId ?? currentUserId;
      
      if (excludeUserId == null || excludeUserId.isEmpty) {
        emit(const BloodRequestError('User not authenticated'));
        return;
      }
      
      final requests = await _supabaseService.getBloodRequestsForHome(
        bloodGroup: event.bloodGroup,
        excludeUserId: excludeUserId,
      );
      emit(BloodRequestsLoaded(requests));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onUpdateBloodRequestStatus(
    UpdateBloodRequestStatusEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      final currentRequest = await _supabaseService.getBloodRequestById(event.requestId);
      if (currentRequest == null) {
        emit(const BloodRequestError('Blood request not found'));
        return;
      }

      final updatedRequest = currentRequest.copyWith(
        status: event.status,
        updatedAt: DateTime.now(),
      );

      final result = await _supabaseService.updateBloodRequest(updatedRequest);
      emit(BloodRequestUpdated(result));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onDeleteBloodRequest(
    DeleteBloodRequestEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      await _supabaseService.deleteBloodRequest(event.requestId);
      emit(BloodRequestDeleted(event.requestId));
    } catch (e) {
      emit(BloodRequestError(e.toString()));
    }
  }

  Future<void> _onAcceptBloodRequest(
    AcceptBloodRequestEvent event,
    Emitter<BloodRequestState> emit,
  ) async {
    emit(const BloodRequestLoading());
    try {
      final result = await _supabaseService.acceptBloodRequest(event.requestId);
      emit(BloodRequestUpdated(result));
    } catch (e) {
      String errorMessage = 'Failed to accept request';
      if (e.toString().contains('PGRST116') || e.toString().contains('0 rows')) {
        errorMessage = 'Request not found or already accepted';
      } else if (e.toString().contains('permission') || e.toString().contains('policy')) {
        errorMessage = 'You do not have permission to accept this request';
      } else {
        errorMessage = e.toString();
      }
      emit(BloodRequestError(errorMessage));
    }
  }
}
