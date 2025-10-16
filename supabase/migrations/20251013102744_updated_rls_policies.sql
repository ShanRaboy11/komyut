-- Fix ALL RLS Policies to Remove Infinite Recursion
-- Run this in Supabase SQL Editor
-- This fixes the profile_id vs user_id confusion

-- ========================================
-- CRITICAL: The Issue
-- ========================================
-- auth.uid() returns the user's auth.users.id (same as profiles.user_id)
-- NOT the profiles.id (profile_id)
--
-- WRONG: profile_id = auth.uid() ❌
-- RIGHT: user_id = auth.uid() ✅
-- OR: profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) ✅

DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Allow authenticated users to insert own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to view own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON profiles;

DROP POLICY IF EXISTS "Commuters can manage own record" ON commuters;
DROP POLICY IF EXISTS "Admins can manage all commuters" ON commuters;
DROP POLICY IF EXISTS "Allow authenticated users to insert commuter" ON commuters;
DROP POLICY IF EXISTS "Allow users to view own commuter" ON commuters;

DROP POLICY IF EXISTS "Admins full access to drivers" ON drivers;
DROP POLICY IF EXISTS "Operators access own drivers" ON drivers;
DROP POLICY IF EXISTS "Drivers access own record" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to insert driver" ON drivers;
DROP POLICY IF EXISTS "Allow users to view own driver" ON drivers;

DROP POLICY IF EXISTS "Operators: admin full access" ON operators;
DROP POLICY IF EXISTS "Operators: self access" ON operators;
DROP POLICY IF EXISTS "Operators: self update" ON operators;
DROP POLICY IF EXISTS "Operators: self insert" ON operators;
DROP POLICY IF EXISTS "Allow authenticated users to insert operator" ON operators;
DROP POLICY IF EXISTS "Allow users to view own operator" ON operators;

DROP POLICY IF EXISTS "Users can access own wallet" ON wallets;
DROP POLICY IF EXISTS "Admins can access all wallets" ON wallets;
DROP POLICY IF EXISTS "Allow authenticated users to insert wallet" ON wallets;
DROP POLICY IF EXISTS "Allow users to view own wallet" ON wallets;
DROP POLICY IF EXISTS "Allow users to update own wallet" ON wallets;

DROP POLICY IF EXISTS "Users can access own attachments" ON attachments;
DROP POLICY IF EXISTS "Admins can access all attachments" ON attachments;
DROP POLICY IF EXISTS "Allow authenticated users to insert attachment" ON attachments;
DROP POLICY IF EXISTS "Allow users to view own attachments" ON attachments;

DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can view all transactions" ON transactions;

DROP POLICY IF EXISTS "Commuters can view their trips" ON trip_participants;
DROP POLICY IF EXISTS "Drivers can view their trips" ON trip_participants;
DROP POLICY IF EXISTS "Admins can view all trip participants" ON trip_participants;

DROP POLICY IF EXISTS "Public can view routes" ON routes;
DROP POLICY IF EXISTS "Admins can manage routes" ON routes;

DROP POLICY IF EXISTS "Public can view route stops" ON route_stops;
DROP POLICY IF EXISTS "Admins can manage route stops" ON route_stops;

DROP POLICY IF EXISTS "Drivers can view own trips" ON trips;
DROP POLICY IF EXISTS "Commuters can view own trips" ON trips;
DROP POLICY IF EXISTS "Admins can manage all trips" ON trips;

DROP POLICY IF EXISTS "Commuters can manage their ratings" ON ratings;
DROP POLICY IF EXISTS "Drivers can view ratings" ON ratings;
DROP POLICY IF EXISTS "Admins can manage all ratings" ON ratings;

DROP POLICY IF EXISTS "Users can manage their own reports" ON reports;
DROP POLICY IF EXISTS "Admins can manage all reports" ON reports;

DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Admins can manage notifications" ON notifications;

DROP POLICY IF EXISTS "Users can view own verifications" ON verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON verifications;

DROP POLICY IF EXISTS "Admins can manage fare policies" ON fare_policies;

DROP POLICY IF EXISTS "Admins can manage fare brackets" ON fare_brackets;

DROP POLICY IF EXISTS "Points Transactions: admin full access" ON points_transactions;
DROP POLICY IF EXISTS "Points Transactions: commuter access" ON points_transactions;
DROP POLICY IF EXISTS "Points Transactions: commuter insert" ON points_transactions;

DROP POLICY IF EXISTS "Audit Logs: admin full access" ON audit_logs;


DROP FUNCTION IF EXISTS is_admin();

CREATE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  );
END;
$$;

CREATE POLICY "profiles_insert_own"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_select_own"
ON profiles FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "profiles_update_own"
ON profiles FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR is_admin())
WITH CHECK (user_id = auth.uid() OR is_admin());

CREATE POLICY "commuters_insert_own"
ON commuters FOR INSERT
TO authenticated
WITH CHECK (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "commuters_select_own"
ON commuters FOR SELECT
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "commuters_update_own"
ON commuters FOR UPDATE
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "drivers_insert_own"
ON drivers FOR INSERT
TO authenticated
WITH CHECK (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "drivers_select_own"
ON drivers FOR SELECT
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "drivers_update_own"
ON drivers FOR UPDATE
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "operators_insert_own"
ON operators FOR INSERT
TO authenticated
WITH CHECK (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "operators_select_own"
ON operators FOR SELECT
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "operators_update_own"
ON operators FOR UPDATE
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "wallets_insert_own"
ON wallets FOR INSERT
TO authenticated
WITH CHECK (
  owner_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "wallets_select_own"
ON wallets FOR SELECT
TO authenticated
USING (
  owner_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "wallets_update_own"
ON wallets FOR UPDATE
TO authenticated
USING (
  owner_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "attachments_insert_own"
ON attachments FOR INSERT
TO authenticated
WITH CHECK (
  owner_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "attachments_select_own"
ON attachments FOR SELECT
TO authenticated
USING (
  owner_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "transactions_select_own"
ON transactions FOR SELECT
TO authenticated
USING (
  wallet_id IN (
    SELECT w.id FROM wallets w
    JOIN profiles p ON p.id = w.owner_profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);

CREATE POLICY "routes_public_select"
ON routes FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "route_stops_public_select"
ON route_stops FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "routes_admin_all"
ON routes FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "route_stops_admin_all"
ON route_stops FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "trips_select_involved"
ON trips FOR SELECT
TO authenticated
USING (
  created_by_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR driver_id IN (
    SELECT d.id FROM drivers d
    JOIN profiles p ON p.id = d.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);

CREATE POLICY "points_transactions_select_own"
ON points_transactions FOR SELECT
TO authenticated
USING (
  commuter_id IN (
    SELECT c.id FROM commuters c
    JOIN profiles p ON p.id = c.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);

CREATE POLICY "points_transactions_insert_own"
ON points_transactions FOR INSERT
TO authenticated
WITH CHECK (
  commuter_id IN (
    SELECT c.id FROM commuters c
    JOIN profiles p ON p.id = c.profile_id
    WHERE p.user_id = auth.uid()
  )
);

CREATE POLICY "notifications_select_own"
ON notifications FOR SELECT
TO authenticated
USING (
  recipient_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "reports_manage_own"
ON reports FOR ALL
TO authenticated
USING (
  reporter_profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "ratings_commuter_manage"
ON ratings FOR ALL
TO authenticated
USING (
  commuter_id IN (
    SELECT c.id FROM commuters c
    JOIN profiles p ON p.id = c.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);

CREATE POLICY "ratings_driver_view"
ON ratings FOR SELECT
TO authenticated
USING (
  driver_id IN (
    SELECT d.id FROM drivers d
    JOIN profiles p ON p.id = d.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);

CREATE POLICY "verifications_select_own"
ON verifications FOR SELECT
TO authenticated
USING (
  profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  OR is_admin()
);

CREATE POLICY "verifications_admin_all"
ON verifications FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "fare_policies_admin_all"
ON fare_policies FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "fare_brackets_admin_all"
ON fare_brackets FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "audit_logs_admin_all"
ON audit_logs FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "trip_participants_select_own"
ON trip_participants FOR SELECT
TO authenticated
USING (
  commuter_id IN (
    SELECT c.id FROM commuters c
    JOIN profiles p ON p.id = c.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR trip_id IN (
    SELECT t.id FROM trips t
    JOIN drivers d ON d.id = t.driver_id
    JOIN profiles p ON p.id = d.profile_id
    WHERE p.user_id = auth.uid()
  )
  OR is_admin()
);


SELECT
  tablename,
  policyname,
  cmd,
  CASE
    WHEN qual IS NOT NULL THEN 'USING clause present'
    ELSE 'No USING clause'
  END as has_using,
  CASE
    WHEN with_check IS NOT NULL THEN 'WITH CHECK clause present'
    ELSE 'No WITH CHECK clause'
  END as has_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

DO $$
BEGIN
    RAISE NOTICE '✅ All RLS policies fixed! Infinite recursion eliminated.';
    RAISE NOTICE '✅ Key fix: Using user_id = auth.uid() for profiles';
    RAISE NOTICE '✅ Key fix: Using profile_id IN (SELECT...) for other tables';
END $$;