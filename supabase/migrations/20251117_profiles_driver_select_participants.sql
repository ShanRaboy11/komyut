-- Migration: allow drivers to read passenger profiles for trips they drive
-- Run as part of migrations or paste into Supabase SQL editor.

-- Remove any existing policy with the same name to be safe
DROP POLICY IF EXISTS "profiles_select_driver_participant" ON profiles;

CREATE POLICY "profiles_select_driver_participant"
ON profiles FOR SELECT
TO authenticated
USING (
  -- Allow when the profile belongs to a commuter who is a participant on a trip
  -- driven by the currently authenticated driver
  id IN (
    SELECT p2.id
    FROM profiles p2
    JOIN commuters c ON c.profile_id = p2.id
    JOIN trip_participants tp ON tp.commuter_id = c.id
    JOIN trips t ON t.id = tp.trip_id
    JOIN drivers d ON d.id = t.driver_id
    JOIN profiles dp ON dp.id = d.profile_id
    WHERE dp.user_id = auth.uid()
  )
  -- Also allow when the profile is the creator of a trip driven by user
  OR id IN (
    SELECT t.created_by_profile_id
    FROM trips t
    JOIN drivers d ON d.id = t.driver_id
    JOIN profiles dp ON dp.id = d.profile_id
    WHERE dp.user_id = auth.uid()
  )
  -- Keep existing allowances for the profile owner or admins
  OR user_id = auth.uid()
  OR is_admin()
);

DO $$
BEGIN
  RAISE NOTICE '✅ profiles_select_driver_participant policy created';
END $$;
