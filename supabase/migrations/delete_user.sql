-- =====================================================
-- Migration: Add delete_user function
-- Run this in Supabase SQL Editor
-- =====================================================

CREATE OR REPLACE FUNCTION delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get the current authenticated user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Remove all joined blood requests (reset status to pending)
  UPDATE public.blood_requests 
  SET accepted_by_user_id = NULL, status = 'pending'
  WHERE accepted_by_user_id = v_user_id;

  -- Remove all created blood requests (or cascade will do this usually, but enforcing it here)
  DELETE FROM public.blood_requests
  WHERE user_id = v_user_id;

  -- Delete from users table (or cascade will do this usually)
  DELETE FROM public.users
  WHERE id = v_user_id;

  -- Finally, delete the auth user
  DELETE FROM auth.users
  WHERE id = v_user_id;

END;
$$;
