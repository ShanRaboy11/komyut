
CREATE POLICY "trips_insert_own"
ON trips FOR INSERT
TO authenticated
WITH CHECK (
  created_by_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "trips_update_own"
ON trips FOR UPDATE
TO authenticated
USING (
  created_by_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR driver_id IN (
    SELECT d.id FROM drivers d
    JOIN profiles p ON p.id = d.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
)
WITH CHECK (
  created_by_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR driver_id IN (
    SELECT d.id FROM drivers d
    JOIN profiles p ON p.id = d.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);


SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  CASE
    WHEN qual IS NOT NULL THEN 'Has USING'
    ELSE 'No USING'
  END as using_clause,
  CASE
    WHEN with_check IS NOT NULL THEN 'Has WITH CHECK'
    ELSE 'No WITH CHECK'
  END as check_clause
FROM pg_policies 
WHERE tablename = 'trips'
ORDER BY policyname;

DO $$
BEGIN
    RAISE NOTICE '✅ Trip INSERT policy added';
    RAISE NOTICE '✅ Trip UPDATE policy added';
    RAISE NOTICE '✅ Commuters can now create and complete trips';
    RAISE NOTICE '✅ Drivers can update trips for their rides';
END $$;