-- Query 1: SELECT distinct categories for a given city/state
SELECT DISTINCT BC.category_name
FROM "Business" B
JOIN "BusinessCategory" BC ON B.business_id = BC.business_id
WHERE B.city = 'Las Vegas' AND B.state = 'NV'
ORDER BY BC.category_name;

-- Query 2: SELECT distinct attributes for a given city/state
SELECT DISTINCT BA.attribute_name, BA.value
FROM "Business" B
JOIN "BusinessAttribute" BA ON B.business_id = BA.business_id
WHERE B.city = 'Las Vegas' AND B.state = 'NV'
ORDER BY BA.attribute_name;

-- Query 3: SELECT businesses in a city/state having all of a given list of categories
SELECT B.business_id, B.name, B.star_rating
FROM "Business" B
WHERE B.city = 'Las Vegas' AND B.state = 'NV'
AND NOT EXISTS (
    SELECT C.category_name
    FROM (VALUES ('Restaurants'), ('Nightlife'), ('Bars')) AS C(category_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM "BusinessCategory" BC
        WHERE BC.business_id = B.business_id
        AND BC.category_name = C.category_name
    )
)
ORDER BY B.star_rating DESC;

-- Query 4: SELECT businesses in a city/state having all of a given list of attributes
SELECT B.business_id, B.name, B.star_rating
FROM "Business" B
WHERE B.city = 'Las Vegas' AND B.state = 'NV'
AND NOT EXISTS (
    SELECT A.attribute_name, A.value
    FROM (VALUES 
        ('WiFi', 'free'), 
        ('RestaurantsDelivery', 'true'), 
        ('OutdoorSeating', 'true')
    ) AS A(attribute_name, value)
    WHERE NOT EXISTS (
        SELECT 1
        FROM "BusinessAttribute" BA
        WHERE BA.business_id = B.business_id
        AND BA.attribute_name = A.attribute_name
        AND BA.value = A.value
    )
)
ORDER BY B.star_rating DESC;

-- Query 5: Combined #3 & #4 plus open hours filter
SELECT B.business_id, B.name, B.star_rating
FROM "Business" B
WHERE B.city = 'Las Vegas' AND B.state = 'NV'
-- Has all specified categories
AND NOT EXISTS (
    SELECT C.category_name
    FROM (VALUES ('Restaurants'), ('Bars')) AS C(category_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM "BusinessCategory" BC
        WHERE BC.business_id = B.business_id
        AND BC.category_name = C.category_name
    )
)
-- Has all specified attributes
AND NOT EXISTS (
    SELECT A.attribute_name, A.value
    FROM (VALUES 
        ('WiFi', 'free'), 
        ('OutdoorSeating', 'true')
    ) AS A(attribute_name, value)
    WHERE NOT EXISTS (
        SELECT 1
        FROM "BusinessAttribute" BA
        WHERE BA.business_id = B.business_id
        AND BA.attribute_name = A.attribute_name
        AND BA.value = A.value
    )
)
-- Is open on Monday at 20:00
AND EXISTS (
    SELECT 1
    FROM "BusinessHours" BH
    WHERE BH.business_id = B.business_id
    AND BH.day_of_week = 'Monday'
    AND BH.open_time <= '20:00'
    AND BH.close_time >= '20:00'
)
ORDER BY B.star_rating DESC;

-- Query 6: Function count_categories(b1 VARCHAR, b2 VARCHAR) RETURNS INTEGER
CREATE OR REPLACE FUNCTION count_categories(b1 VARCHAR, b2 VARCHAR) 
RETURNS INTEGER AS $$
DECLARE
    common_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO common_count
    FROM "BusinessCategory" BC1
    JOIN "BusinessCategory" BC2 ON BC1.category_name = BC2.category_name
    WHERE BC1.business_id = b1 AND BC2.business_id = b2;
    
    RETURN common_count;
END;
$$ LANGUAGE plpgsql;

-- Example of using count_categories
SELECT count_categories('RESDUcs6mBiYjdUJUGAkmA', 'K7lWdNUhCbcnEvI0NhGewg') AS common_categories;

-- Query 7: Function geodistance(lat1 float, lon1 float, lat2 float, lon2 float) RETURNS DOUBLE PRECISION
CREATE OR REPLACE FUNCTION geodistance(lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION, 
                                      lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION) 
RETURNS DOUBLE PRECISION AS $$
DECLARE
    dist DOUBLE PRECISION;
    radius_earth DOUBLE PRECISION := 3959; -- in miles
    lat1_rad DOUBLE PRECISION;
    lat2_rad DOUBLE PRECISION;
    delta_lat_rad DOUBLE PRECISION;
    delta_lon_rad DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    -- Convert latitude and longitude from degrees to radians
    lat1_rad := lat1 * PI() / 180;
    lat2_rad := lat2 * PI() / 180;
    delta_lat_rad := (lat2 - lat1) * PI() / 180;
    delta_lon_rad := (lon2 - lon1) * PI() / 180;
    
    -- Haversine formula
    a := SIN(delta_lat_rad/2) * SIN(delta_lat_rad/2) +
         COS(lat1_rad) * COS(lat2_rad) * 
         SIN(delta_lon_rad/2) * SIN(delta_lon_rad/2);
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    dist := radius_earth * c;
    
    RETURN dist;
END;
$$ LANGUAGE plpgsql;

-- Example of using geodistance
SELECT geodistance(36.12, -115.17, 36.11, -115.18) AS distance_in_miles;

-- Query 8: Given a business_id, return top 15 similar businesses
CREATE OR REPLACE FUNCTION find_similar_businesses(target_id VARCHAR) 
RETURNS TABLE(business_id VARCHAR, name TEXT, distance DOUBLE PRECISION, common_categories INTEGER) AS $$
BEGIN
    RETURN QUERY
    WITH target_business AS (
        SELECT business_id, zipcode, latitude, longitude
        FROM "Business"
        WHERE business_id = target_id
    )
    SELECT b.business_id, b.name, 
           geodistance(tb.latitude, tb.longitude, b.latitude, b.longitude) AS distance,
           count_categories(tb.business_id, b.business_id) AS common_categories
    FROM target_business tb
    JOIN "Business" b ON tb.zipcode = b.zipcode
    WHERE b.business_id != tb.business_id
    AND geodistance(tb.latitude, tb.longitude, b.latitude, b.longitude) <= 20
    ORDER BY common_categories DESC, distance ASC
    LIMIT 15;
END;
$$ LANGUAGE plpgsql;

-- Example of using find_similar_businesses
SELECT * FROM find_similar_businesses('RESDUcs6mBiYjdUJUGAkmA');

-- Query 9: Given zipcode & category, find business(es) with maximum num_tips
SELECT B.business_id, B.name, B.num_tips
FROM "Business" B
JOIN "BusinessCategory" BC ON B.business_id = BC.business_id
WHERE B.zipcode = '89109'
AND BC.category_name = 'Restaurants'
AND B.num_tips = (
    SELECT MAX(B2.num_tips)
    FROM "Business" B2
    JOIN "BusinessCategory" BC2 ON B2.business_id = BC2.business_id
    WHERE B2.zipcode = '89109'
    AND BC2.category_name = 'Restaurants'
)
ORDER BY B.name;

-- Query 10: Given a user_id, find the most recent tip by any of that user's friends
SELECT F.friend_id, U.name AS friend_name, T.tip_date, T.tip_text
FROM "Friendship" F
JOIN "User" U ON F.friend_id = U.user_id
JOIN "Tip" T ON F.friend_id = T.user_id
WHERE F.user_id = '4XChL029mKr5hydo79Ljxg'
ORDER BY T.tip_date DESC
LIMIT 1;

-- Query 11: Given a user_id, find the most recent tip per friend
WITH RankedTips AS (
    SELECT 
        F.friend_id,
        U.name AS friend_name,
        T.tip_date,
        T.tip_text,
        ROW_NUMBER() OVER (PARTITION BY F.friend_id ORDER BY T.tip_date DESC) as row_num
    FROM "Friendship" F
    JOIN "User" U ON F.friend_id = U.user_id
    JOIN "Tip" T ON F.friend_id = T.user_id
    WHERE F.user_id = '4XChL029mKr5hydo79Ljxg'
)
SELECT friend_id, friend_name, tip_date, tip_text
FROM RankedTips
WHERE row_num = 1
ORDER BY tip_date DESC;

-- Query 12: Trigger after_insert_tip()
CREATE OR REPLACE FUNCTION after_insert_tip()
RETURNS TRIGGER AS $$
BEGIN
    -- Increment business num_tips
    UPDATE "Business"
    SET num_tips = num_tips + 1
    WHERE business_id = NEW.business_id;
    
    -- Increment user tip_count
    UPDATE "User"
    SET tip_count = tip_count + 1
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_after_insert_tip
AFTER INSERT ON "Tip"
FOR EACH ROW
EXECUTE FUNCTION after_insert_tip();

-- Test the trigger with an INSERT
INSERT INTO "Tip" (business_id, user_id, tip_date, tip_text, likes)
VALUES ('RESDUcs6mBiYjdUJUGAkmA', '4XChL029mKr5hydo79Ljxg', CURRENT_DATE, 'Great place, would come again!', 0);

-- Check that counts were incremented
SELECT business_id, num_tips FROM "Business" WHERE business_id = 'RESDUcs6mBiYjdUJUGAkmA';
SELECT user_id, tip_count FROM "User" WHERE user_id = '4XChL029mKr5hydo79Ljxg';

-- Query 13: Trigger before_insert_checkin()
CREATE OR REPLACE FUNCTION before_insert_checkin()
RETURNS TRIGGER AS $$
DECLARE
    day_name TEXT;
    time_part TIME;
    is_open BOOLEAN := FALSE;
BEGIN
    -- Extract day of week and time from timestamp
    day_name := to_char(NEW.checkin_timestamp, 'Day');
    time_part := CAST(to_char(NEW.checkin_timestamp, 'HH24:MI:SS') AS TIME);
    
    -- Check if business is open at this time
    SELECT COUNT(*) > 0 INTO is_open
    FROM "BusinessHours" BH
    WHERE BH.business_id = NEW.business_id
    AND BH.day_of_week = TRIM(day_name)
    AND BH.open_time <= time_part
    AND BH.close_time >= time_part;
    
    IF NOT is_open THEN
        RAISE EXCEPTION 'Cannot check in when business is closed: % is not open on % at %', 
                        NEW.business_id, TRIM(day_name), time_part;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_before_insert_checkin
BEFORE INSERT ON "Checkin"
FOR EACH ROW
EXECUTE FUNCTION before_insert_checkin();

-- Test cases for checkin trigger (positive and negative examples)
-- Positive test: Business is open
INSERT INTO "Checkin" (business_id, checkin_timestamp)
VALUES ('RESDUcs6mBiYjdUJUGAkmA', '2023-05-01 18:30:00');

-- Negative test: Business is closed
INSERT INTO "Checkin" (business_id, checkin_timestamp)
VALUES ('RESDUcs6mBiYjdUJUGAkmA', '2023-05-01 03:30:00'); 