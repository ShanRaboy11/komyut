-- Enable Row Level Security on drivers table
-- Fixing scan issue by allowing commuters to see active drivers
DROP POLICY IF EXISTS "drivers_select_own" ON drivers;


CREATE POLICY "drivers_select_own"
ON drivers FOR SELECT
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "drivers_select_active_public"
ON drivers FOR SELECT
TO authenticated
USING (
  active = true 
);


SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'drivers'
ORDER BY policyname;

DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies updated for drivers table';
    RAISE NOTICE '✅ Drivers can see their own record';
    RAISE NOTICE '✅ ALL authenticated users can see active drivers';
    RAISE NOTICE '✅ Commuters can now scan QR codes from any active driver';
END $$;