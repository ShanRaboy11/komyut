CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('admin','commuter','driver','operator');
CREATE TYPE commuter_category AS ENUM ('regular','senior','student','pwd');
CREATE TYPE report_category AS ENUM ('vehicle','driver','traffic','lost_item','safety_security','app','miscellaneous','route');
CREATE TYPE report_status AS ENUM ('open','in_review','resolved','dismissed','closed');
CREATE TYPE report_severity AS ENUM ('low','medium','high');
CREATE TYPE trip_status AS ENUM ('ongoing','completed','cancelled');
CREATE TYPE transaction_type AS ENUM ('cash_in','cash_out','fare_payment','points_redemption','driver_payout','operator_payout');
CREATE TYPE transaction_status AS ENUM ('pending','completed','failed');
CREATE TYPE notification_type AS ENUM ('trip','wallet','rewards','verification','report','system');
CREATE TYPE verification_status AS ENUM ('pending','approved','rejected','lacking');

CREATE OR REPLACE FUNCTION komyut_update_timestamp()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE, 
  role user_role NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  dob date,
  age integer,
  sex varchar(16),
  phone text,
  address text,
  is_verified boolean DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles
  ADD CONSTRAINT fk_profiles_auth_user
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX idx_profiles_role ON profiles(role);

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  bucket text,
  path text,
  url text,
  content_type text,
  size_bytes bigint,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_attachments_owner ON attachments(owner_profile_id);

CREATE TABLE operators (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  company_name text,
  company_address text,
  contact_email text,
  contact_phone text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_operators_updated_at
BEFORE UPDATE ON operators
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  license_number text NOT NULL,
  license_image_url text,
  status boolean DEFAULT false,
  operator_id uuid REFERENCES operators(id) ON DELETE SET NULL,
  operator_name text, 
  current_qr text UNIQUE, 
  vehicle_plate text,
  route_code text,
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_drivers_updated_at
BEFORE UPDATE ON drivers
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE INDEX idx_drivers_operator ON drivers(operator_id);

CREATE TABLE commuters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  category commuter_category NOT NULL DEFAULT 'regular',
  attachment_id uuid REFERENCES attachments(id) ON DELETE SET NULL,
  id_verified boolean DEFAULT false,
  wheel_tokens integer DEFAULT 0 CHECK (wheel_tokens >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_commuters_updated_at
BEFORE UPDATE ON commuters
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL, 
  name text,
  description text,
  start_lat numeric(10,6),
  start_lng numeric(10,6),
  end_lat numeric(10,6),
  end_lng numeric(10,6),
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE TRIGGER trg_routes_updated_at
BEFORE UPDATE ON routes
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE route_stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid REFERENCES routes(id) ON DELETE CASCADE,
  name text NOT NULL,
  sequence integer NOT NULL,
  latitude numeric(10,6),
  longitude numeric(10,6),
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_route_stops_route_seq ON route_stops(route_id, sequence);

CREATE TABLE trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
  origin_stop_id uuid REFERENCES route_stops(id) ON DELETE SET NULL,
  destination_stop_id uuid REFERENCES route_stops(id) ON DELETE SET NULL,
  distance_meters integer CHECK (distance_meters >= 0),
  fare_amount numeric(12,2) CHECK (fare_amount >= 0),
  passengers_count integer DEFAULT 1 CHECK (passengers_count >= 1),
  status trip_status NOT NULL DEFAULT 'ongoing',
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  created_by_profile_id uuid REFERENCES profiles(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}'::jsonb
);

CREATE TRIGGER trg_trips_updated_at
BEFORE UPDATE ON trips
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE OR REPLACE FUNCTION komyut_generate_transaction_number()
RETURNS text AS $$
BEGIN
  RETURN concat('EXCHAND-', to_char(now(),'YYYYMMDDHH24MISS'), '-', substr(md5(gen_random_uuid()::text),1,6));
END;
$$ LANGUAGE plpgsql;

-- Wallets
CREATE TABLE wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  balance numeric(14,2) DEFAULT 0 CHECK (balance >= 0),
  locked boolean DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE UNIQUE INDEX uq_wallet_owner ON wallets(owner_profile_id);
CREATE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number text UNIQUE DEFAULT komyut_generate_transaction_number(),
  wallet_id uuid REFERENCES wallets(id) ON DELETE SET NULL,
  initiated_by_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  type transaction_type NOT NULL,
  amount numeric(14,2) NOT NULL CHECK (amount >= 0),
  fee numeric(14,2) DEFAULT 0 CHECK (fee >= 0),
  status transaction_status DEFAULT 'pending',
  related_trip_id uuid REFERENCES trips(id) ON DELETE SET NULL,
  external_reference text, 
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  processed_at timestamptz
);


CREATE TABLE trip_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE,
  commuter_id uuid REFERENCES commuters(id) ON DELETE SET NULL,
  payer_profile_id uuid REFERENCES profiles(id) NOT NULL,
  passenger_count integer DEFAULT 1 CHECK(passenger_count >= 1),
  fare_per_person numeric(12,2) CHECK (fare_per_person >= 0),
  transaction_id uuid REFERENCES transactions(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_trip_participants_trip ON trip_participants(trip_id);

CREATE UNIQUE INDEX uq_commuter_ongoing_trip
ON trips(created_by_profile_id)
WHERE status = 'ongoing';


CREATE TABLE points_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  commuter_id uuid REFERENCES commuters(id) ON DELETE CASCADE,
  change integer NOT NULL, 
  reason text,
  related_transaction_id uuid REFERENCES transactions(id) ON DELETE SET NULL,
  balance_after integer,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_points_commuter ON points_transactions(commuter_id);

CREATE TABLE ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE,
  commuter_id uuid REFERENCES commuters(id) ON DELETE SET NULL,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  courtesy smallint CHECK (courtesy BETWEEN 1 AND 5),
  safety smallint CHECK (safety BETWEEN 1 AND 5),
  vehicle_condition smallint CHECK (vehicle_condition BETWEEN 1 AND 5),
  overall smallint CHECK (overall BETWEEN 1 AND 5),
  app_experience smallint CHECK (app_experience BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_ratings_driver ON ratings(driver_id);

CREATE TABLE reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  reported_entity_type text,
  reported_entity_id uuid,
  category report_category,
  severity report_severity,
  status report_status DEFAULT 'open',
  description text,
  attachment_id uuid REFERENCES attachments(id) ON DELETE SET NULL,
  assigned_to_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL, 
  resolution_notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX idx_reports_status ON reports(status);
CREATE TRIGGER trg_reports_updated_at
BEFORE UPDATE ON reports
FOR EACH ROW
EXECUTE FUNCTION komyut_update_timestamp();

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type,
  title text,
  message text,
  payload jsonb DEFAULT '{}'::jsonb,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_profile_id, read);

CREATE TABLE verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  verification_type text, 
  attachment_id uuid REFERENCES attachments(id) ON DELETE SET NULL,
  status verification_status DEFAULT 'pending',
  reviewer_profile_id uuid REFERENCES profiles(id),
  reviewer_notes text,
  created_at timestamptz DEFAULT now(),
  reviewed_at timestamptz
);

CREATE TABLE fare_policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  description text,
  base_fare numeric(12,2) DEFAULT 0,
  per_km numeric(12,2) DEFAULT 0,
  active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE fare_brackets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fare_policy_id uuid REFERENCES fare_policies(id) ON DELETE CASCADE,
  min_distance integer NOT NULL,
  max_distance integer NOT NULL,
  price numeric(12,2) NOT NULL
);
CREATE INDEX idx_fare_brackets_policy ON fare_brackets(fare_policy_id);

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  action text,
  target_table text,
  target_id uuid,
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_driver_revenue AS
SELECT
  d.id AS driver_id,
  (p.first_name || ' ' || p.last_name) AS driver_name,
  SUM(t.amount) FILTER (WHERE t.type = 'fare_payment' AND t.status='completed') AS total_fares,
  COUNT(DISTINCT tr.id) AS total_trips
FROM drivers d
LEFT JOIN profiles p ON p.id = d.profile_id
LEFT JOIN trips tr ON tr.driver_id = d.id
LEFT JOIN transactions t ON t.related_trip_id = tr.id
GROUP BY d.id, p.first_name, p.last_name;

ALTER TABLE drivers 
ADD COLUMN route_id uuid REFERENCES routes(id) ON DELETE SET NULL;

-- Migrate existing data
UPDATE drivers d
SET route_id = r.id
FROM routes r
WHERE d.route_code = r.code;

-- Add index
CREATE INDEX idx_drivers_route ON drivers(route_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_trips_driver_started_at ON trips(driver_id, started_at);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_verifications_status ON verifications(status);

-- ==== CASH-IN COMPLETION FUNCTION (RPC) ====
CREATE OR REPLACE FUNCTION complete_otc_cash_in(transaction_id_arg uuid)
RETURNS void AS $$
DECLARE
  trans RECORD;
BEGIN
  -- Find the specific transaction that needs to be completed
  SELECT * INTO trans FROM public.transactions WHERE id = transaction_id_arg FOR UPDATE;

  -- Security check: ensure the transaction exists and is in the correct state
  IF NOT FOUND OR trans.status <> 'pending' OR trans.type <> 'cash_in' THEN
    RAISE EXCEPTION 'Transaction not found or not in a completable state.';
  END IF;

  -- Add the amount to the user's wallet
  UPDATE public.wallets
  SET balance = balance + trans.amount
  WHERE id = trans.wallet_id;

  -- Mark the transaction as completed and set the processing time
  UPDATE public.transactions
  SET 
    status = 'completed',
    processed_at = now()
  WHERE id = transaction_id_arg;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ROW LEVEL SECURITY (RLS) POLICIES FOR TRANSACTIONS ====
-- enable RLS on the table
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- allow users to INSERT their own transactions
CREATE POLICY "Users can insert their own transactions"
ON public.transactions
FOR INSERT
WITH CHECK (
  auth.uid() = (
    SELECT user_id FROM profiles WHERE id = initiated_by_profile_id
  )
);

-- allow users to VIEW transactions related to their wallet
CREATE POLICY "Users can view their own transactions"
ON public.transactions
FOR SELECT
USING (
  auth.uid() = (
    SELECT p.user_id 
    FROM profiles p 
    JOIN wallets w ON p.id = w.owner_profile_id
    WHERE w.id = transactions.wallet_id
  )
);