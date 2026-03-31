import 'package:bloc/bloc.dart';
import 'donor_events.dart';
import 'donor_states.dart';
import '../../data/managers/remote/supabase_service.dart';

class DonorBloc extends Bloc<DonorEvent, DonorState> {
  final SupabaseService _supabaseService;

  DonorBloc(this._supabaseService) : super(const DonorInitial()) {
    on<GetDonorsEvent>(_onGetDonors);
  }

  Future<void> _onGetDonors(
    GetDonorsEvent event,
    Emitter<DonorState> emit,
  ) async {
    emit(const DonorLoading());
    try {
      final currentUserId = _supabaseService.client.auth.currentUser?.id;
      final donors = await _supabaseService.getAllDonors(
        excludeUserId: currentUserId,
        country: event.country,
        city: event.city,
      );
      emit(DonorsLoaded(donors));
    } catch (e) {
      emit(DonorError(e.toString()));
    }
  }
}
