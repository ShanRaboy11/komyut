ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Audit Logs: admin full access"
ON audit_logs
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND p.role = 'admin'
  )
);


ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Points Transactions: admin full access"
ON points_transactions
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND p.role = 'admin'
  )
);

CREATE POLICY "Points Transactions: commuter access"
ON points_transactions
FOR SELECT
USING (
  commuter_id IN (
    SELECT id FROM commuters WHERE profile_id = auth.uid()
  )
);

CREATE POLICY "Points Transactions: commuter insert"
ON points_transactions
FOR INSERT
WITH CHECK (
  commuter_id IN (
    SELECT id FROM commuters WHERE profile_id = auth.uid()
  )
);

ALTER TABLE operators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Operators: admin full access"
ON operators
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles p WHERE p.user_id = auth.uid() AND p.role = 'admin'
  )
);

CREATE POLICY "Operators: self access"
ON operators
FOR SELECT
USING (profile_id = auth.uid());

CREATE POLICY "Operators: self update"
ON operators
FOR UPDATE
USING (profile_id = auth.uid());

CREATE POLICY "Operators: self insert"
ON operators
FOR INSERT
WITH CHECK (profile_id = auth.uid());
