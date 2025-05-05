UPDATE "Business"
SET num_tips = (
    SELECT COUNT(*)
    FROM "Tip"
    WHERE "Tip".business_id = "Business".business_id
);

UPDATE "User"
SET tip_count = (
    SELECT COUNT(*)
    FROM "Tip"
    WHERE "Tip".user_id = "User".user_id
);

SELECT B.business_id, B.name, B.num_tips, COUNT(T.business_id) AS actual_tip_count
FROM "Business" B
LEFT JOIN "Tip" T ON B.business_id = T.business_id
WHERE B.business_id = 'RESDUcs6mBiYjdUJUGAkmA'
GROUP BY B.business_id, B.name, B.num_tips;

SELECT U.user_id, U.name, U.tip_count, COUNT(T.user_id) AS actual_tip_count
FROM "User" U
LEFT JOIN "Tip" T ON U.user_id = T.user_id
WHERE U.user_id = '4XChL029mKr5hydo79Ljxg'
GROUP BY U.user_id, U.name, U.tip_count; 