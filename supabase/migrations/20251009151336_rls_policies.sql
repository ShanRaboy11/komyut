ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own profile"
ON profiles
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own profile"
ON profiles
FOR UPDATE
USING (user_id = auth.uid());

CREATE POLICY "Admins can read all profiles"
ON profiles
FOR SELECT
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "Admins can update all profiles"
ON profiles
FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE commuters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commuters can manage own record"
ON commuters
FOR ALL
USING (profile_id = auth.uid());

CREATE POLICY "Admins can manage all commuters"
ON commuters
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins full access to drivers"
ON drivers
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles p 
    WHERE p.user_id = auth.uid() AND p.role = 'admin'
  )
);

CREATE POLICY "Operators access own drivers"
ON drivers
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM operators o
    JOIN profiles p ON p.id = o.profile_id
    WHERE o.id = drivers.operator_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Drivers access own record"
ON drivers
FOR SELECT
USING (profile_id = auth.uid());


ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access own wallet"
ON wallets
FOR ALL
USING (owner_profile_id = auth.uid());

CREATE POLICY "Admins can access all wallets"
ON wallets
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
ON transactions
FOR SELECT
USING (wallet_id IN (
  SELECT id FROM wallets WHERE owner_profile_id = auth.uid()
));

CREATE POLICY "Admins can view all transactions"
ON transactions
FOR SELECT
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE trip_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commuters can view their trips"
ON trip_participants
FOR SELECT
USING (commuter_id = auth.uid());

CREATE POLICY "Drivers can view their trips"
ON trip_participants
FOR SELECT
USING (trip_id IN (
  SELECT id FROM trips WHERE driver_id = auth.uid()
));

CREATE POLICY "Admins can view all trip participants"
ON trip_participants
FOR SELECT
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access own attachments"
ON attachments
FOR ALL
USING (owner_profile_id = auth.uid());

CREATE POLICY "Admins can access all attachments"
ON attachments
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view routes"
ON routes
FOR SELECT
USING (true);

CREATE POLICY "Public can view route stops"
ON route_stops
FOR SELECT
USING (true);

CREATE POLICY "Admins can manage routes"
ON routes
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "Admins can manage route stops"
ON route_stops
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can view own trips"
ON trips
FOR SELECT
USING (driver_id = auth.uid());

CREATE POLICY "Commuters can view own trips"
ON trips
FOR SELECT
USING (created_by_profile_id = auth.uid());

CREATE POLICY "Admins can manage all trips"
ON trips
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Commuters can manage their ratings"
ON ratings
FOR ALL
USING (commuter_id = auth.uid());

CREATE POLICY "Drivers can view ratings"
ON ratings
FOR SELECT
USING (driver_id = auth.uid());

CREATE POLICY "Admins can manage all ratings"
ON ratings
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own reports"
ON reports
FOR ALL
USING (reporter_profile_id = auth.uid());

CREATE POLICY "Admins can manage all reports"
ON reports
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
ON notifications
FOR SELECT
USING (recipient_profile_id = auth.uid());

CREATE POLICY "Admins can manage notifications"
ON notifications
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own verifications"
ON verifications
FOR SELECT
USING (profile_id = auth.uid());

CREATE POLICY "Admins can manage verifications"
ON verifications
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

ALTER TABLE fare_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE fare_brackets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage fare policies"
ON fare_policies
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));

CREATE POLICY "Admins can manage fare brackets"
ON fare_brackets
FOR ALL
USING (EXISTS (
  SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND role = 'admin'
));
