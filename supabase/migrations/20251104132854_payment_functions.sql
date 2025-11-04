-- Function to process initial boarding payment
CREATE OR REPLACE FUNCTION process_boarding_payment(
    p_profile_id uuid,
    p_driver_id uuid,
    p_route_id uuid,
    p_boarding_lat numeric,
    p_boarding_lng numeric,
    p_qr_code text,
    p_puv_type text
)
RETURNS jsonb AS $$
DECLARE
    v_wallet_id uuid;
    v_balance numeric;
    v_initial_payment numeric := 10.00;
    v_trip_id uuid;
    v_transaction_id uuid;
    v_transaction_number text;
BEGIN
    -- Check if user already has an ongoing trip
    IF EXISTS (
        SELECT 1 FROM trips 
        WHERE created_by_profile_id = p_profile_id 
        AND status = 'ongoing'
    ) THEN
        RAISE EXCEPTION 'You already have an ongoing trip';
    END IF;

    -- Get wallet
    SELECT id, balance INTO v_wallet_id, v_balance
    FROM wallets
    WHERE owner_profile_id = p_profile_id
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    -- Check balance
    IF v_balance < v_initial_payment THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', v_balance, v_initial_payment;
    END IF;

    -- Generate transaction number
    v_transaction_number := 'TXN-' || EXTRACT(EPOCH FROM now())::bigint || '-' || floor(random() * 1000)::int;

    -- Deduct from wallet
    UPDATE wallets
    SET balance = balance - v_initial_payment
    WHERE id = v_wallet_id;

    -- Create transaction
    INSERT INTO transactions (
        transaction_number,
        wallet_id,
        initiated_by_profile_id,
        type,
        amount,
        status,
        metadata
    ) VALUES (
        v_transaction_number,
        v_wallet_id,
        p_profile_id,
        'fare_payment',
        v_initial_payment,
        'pending',
        jsonb_build_object(
            'payment_type', 'initial_boarding',
            'puv_type', p_puv_type
        )
    ) RETURNING id INTO v_transaction_id;

    -- Create trip
    INSERT INTO trips (
        driver_id,
        route_id,
        created_by_profile_id,
        status,
        fare_amount,
        started_at,
        metadata
    ) VALUES (
        p_driver_id,
        p_route_id,
        p_profile_id,
        'ongoing',
        v_initial_payment,
        now(),
        jsonb_build_object(
            'takeoff_qr', p_qr_code,
            'boarding_location', jsonb_build_object(
                'latitude', p_boarding_lat,
                'longitude', p_boarding_lng,
                'timestamp', now()
            ),
            'initial_payment', v_initial_payment,
            'puv_type', p_puv_type
        )
    ) RETURNING id INTO v_trip_id;

    -- Link transaction to trip
    UPDATE transactions
    SET related_trip_id = v_trip_id
    WHERE id = v_transaction_id;

    RETURN jsonb_build_object(
        'success', true,
        'trip_id', v_trip_id,
        'transaction_id', v_transaction_id,
        'transaction_number', v_transaction_number,
        'amount_paid', v_initial_payment,
        'remaining_balance', v_balance - v_initial_payment
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete trip and process final payment
CREATE OR REPLACE FUNCTION complete_trip_payment(
    p_trip_id uuid,
    p_arrival_lat numeric,
    p_arrival_lng numeric,
    p_distance_meters integer
)
RETURNS jsonb AS $$
DECLARE
    v_trip record;
    v_profile_id uuid;
    v_driver_id uuid;
    v_driver_profile_id uuid;
    v_wallet_id uuid;
    v_driver_wallet_id uuid;
    v_balance numeric;
    v_driver_balance numeric;
    v_initial_payment numeric;
    v_total_fare numeric;
    v_additional_fare numeric;
    v_puv_type text;
    v_distance_km numeric;
    v_base_fare numeric;
    v_base_distance numeric := 4.0;
    v_per_km_rate numeric := 1.0;
    v_transaction_number text;
    v_transaction_id uuid;
BEGIN
    -- Get trip details
    SELECT * INTO v_trip
    FROM trips
    WHERE id = p_trip_id
    FOR UPDATE;

    IF v_trip IS NULL THEN
        RAISE EXCEPTION 'Trip not found';
    END IF;

    IF v_trip.status != 'ongoing' THEN
        RAISE EXCEPTION 'Trip is not ongoing';
    END IF;

    v_profile_id := v_trip.created_by_profile_id;
    v_driver_id := v_trip.driver_id;
    v_initial_payment := (v_trip.metadata->>'initial_payment')::numeric;
    v_puv_type := v_trip.metadata->>'puv_type';

    -- Calculate distance and fare
    v_distance_km := p_distance_meters / 1000.0;

    -- Determine base fare based on PUV type
    IF LOWER(v_puv_type) = 'modern' THEN
        v_base_fare := 15.0;
    ELSE
        v_base_fare := 13.0;
    END IF;

    -- Calculate total fare
    IF v_distance_km <= v_base_distance THEN
        v_total_fare := v_base_fare;
    ELSE
        v_total_fare := v_base_fare + ((v_distance_km - v_base_distance) * v_per_km_rate);
    END IF;

    -- Calculate additional fare (after initial payment)
    v_additional_fare := v_total_fare - v_initial_payment;
    IF v_additional_fare < 0 THEN
        v_additional_fare := 0;
    END IF;

    -- Get commuter wallet
    SELECT id, balance INTO v_wallet_id, v_balance
    FROM wallets
    WHERE owner_profile_id = v_profile_id
    FOR UPDATE;

    -- Get driver profile and wallet
    SELECT profile_id INTO v_driver_profile_id
    FROM drivers
    WHERE id = v_driver_id;

    SELECT id, balance INTO v_driver_wallet_id, v_driver_balance
    FROM wallets
    WHERE owner_profile_id = v_driver_profile_id
    FOR UPDATE;

    -- Process additional payment if needed
    IF v_additional_fare > 0 THEN
        -- Check balance
        IF v_balance < v_additional_fare THEN
            RAISE EXCEPTION 'Insufficient balance for additional fare. Current: %, Required: %', 
                v_balance, v_additional_fare;
        END IF;

        -- Deduct additional fare from commuter
        UPDATE wallets
        SET balance = balance - v_additional_fare
        WHERE id = v_wallet_id;

        -- Generate transaction number
        v_transaction_number := 'TXN-' || EXTRACT(EPOCH FROM now())::bigint || '-' || floor(random() * 1000)::int;

        -- Create transaction for additional payment
        INSERT INTO transactions (
            transaction_number,
            wallet_id,
            initiated_by_profile_id,
            type,
            amount,
            status,
            related_trip_id,
            processed_at,
            metadata
        ) VALUES (
            v_transaction_number,
            v_wallet_id,
            v_profile_id,
            'fare_payment',
            v_additional_fare,
            'completed',
            p_trip_id,
            now(),
            jsonb_build_object(
                'payment_type', 'additional_fare',
                'distance_km', v_distance_km,
                'puv_type', v_puv_type
            )
        ) RETURNING id INTO v_transaction_id;
    END IF;

    -- Transfer total fare to driver
    IF v_driver_wallet_id IS NOT NULL THEN
        UPDATE wallets
        SET balance = balance + v_total_fare
        WHERE id = v_driver_wallet_id;
    END IF;

    -- Mark initial transaction as completed
    UPDATE transactions
    SET status = 'completed',
        processed_at = now()
    WHERE related_trip_id = p_trip_id
    AND status = 'pending';

    -- Update trip as completed
    UPDATE trips
    SET status = 'completed',
        distance_meters = p_distance_meters,
        fare_amount = v_total_fare,
        ended_at = now(),
        metadata = v_trip.metadata || jsonb_build_object(
            'arrival_location', jsonb_build_object(
                'latitude', p_arrival_lat,
                'longitude', p_arrival_lng,
                'timestamp', now()
            ),
            'total_fare', v_total_fare,
            'additional_fare', v_additional_fare,
            'distance_km', v_distance_km
        )
    WHERE id = p_trip_id;

    RETURN jsonb_build_object(
        'success', true,
        'trip_id', p_trip_id,
        'total_fare', v_total_fare,
        'initial_payment', v_initial_payment,
        'additional_fare', v_additional_fare,
        'distance_km', v_distance_km,
        'transaction_number', v_transaction_number
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get trip summary
CREATE OR REPLACE FUNCTION get_trip_summary(p_trip_id uuid)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'trip_id', t.id,
        'status', t.status,
        'started_at', t.started_at,
        'ended_at', t.ended_at,
        'distance_meters', t.distance_meters,
        'distance_km', ROUND((t.distance_meters / 1000.0)::numeric, 2),
        'fare_amount', t.fare_amount,
        'driver', jsonb_build_object(
            'name', p.first_name || ' ' || p.last_name,
            'vehicle_plate', d.vehicle_plate,
            'puv_type', d.puv_type
        ),
        'route', jsonb_build_object(
            'code', r.code,
            'name', r.name
        ),
        'locations', jsonb_build_object(
            'boarding', t.metadata->'boarding_location',
            'arrival', t.metadata->'arrival_location'
        ),
        'transactions', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'transaction_number', tr.transaction_number,
                    'amount', tr.amount,
                    'type', tr.type,
                    'status', tr.status,
                    'created_at', tr.created_at
                )
            )
            FROM transactions tr
            WHERE tr.related_trip_id = t.id
        )
    ) INTO v_result
    FROM trips t
    LEFT JOIN drivers d ON t.driver_id = d.id
    LEFT JOIN profiles p ON d.profile_id = p.id
    LEFT JOIN routes r ON t.route_id = r.id
    WHERE t.id = p_trip_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_trips_profile_status ON trips(created_by_profile_id, status);
CREATE INDEX IF NOT EXISTS idx_transactions_trip ON transactions(related_trip_id);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet ON transactions(wallet_id);