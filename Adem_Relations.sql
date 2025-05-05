DROP TABLE IF EXISTS "BusinessHours";
DROP TABLE IF EXISTS "BusinessAttribute";
DROP TABLE IF EXISTS "BusinessCategory";
DROP TABLE IF EXISTS "Checkin";
DROP TABLE IF EXISTS "Tip";
DROP TABLE IF EXISTS "Friendship";
DROP TABLE IF EXISTS "Attribute";
DROP TABLE IF EXISTS "Category";
DROP TABLE IF EXISTS "Business";
DROP TABLE IF EXISTS "User";

CREATE TABLE "User" (
    user_id VARCHAR(22) PRIMARY KEY,
    name TEXT NOT NULL,
    average_stars REAL NOT NULL,
    funny_score INTEGER NOT NULL,
    useful_score INTEGER NOT NULL,
    cool_score INTEGER NOT NULL,
    num_fans INTEGER NOT NULL DEFAULT 0,
    tip_count INTEGER NOT NULL DEFAULT 0,
    yelping_since DATE NOT NULL
);

CREATE TABLE "Business" (
    business_id VARCHAR(22) PRIMARY KEY,
    name TEXT NOT NULL,
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    state CHAR(2) NOT NULL,
    zipcode VARCHAR(10) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_open SMALLINT NOT NULL,
    star_rating REAL NOT NULL,
    num_tips INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE "Category" (
    category_name TEXT PRIMARY KEY
);

CREATE TABLE "Attribute" (
    attribute_name TEXT PRIMARY KEY
);

CREATE TABLE "Friendship" (
    user_id VARCHAR(22) NOT NULL,
    friend_id VARCHAR(22) NOT NULL,
    PRIMARY KEY(user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES "User"(user_id),
    FOREIGN KEY (friend_id) REFERENCES "User"(user_id)
);

CREATE TABLE "Tip" (
    business_id VARCHAR(22) NOT NULL,
    user_id VARCHAR(22) NOT NULL,
    tip_date DATE NOT NULL,
    tip_text TEXT NOT NULL,
    likes INTEGER NOT NULL,
    PRIMARY KEY(business_id, user_id, tip_date),
    FOREIGN KEY (business_id) REFERENCES "Business"(business_id),
    FOREIGN KEY (user_id) REFERENCES "User"(user_id)
);

CREATE TABLE "Checkin" (
    business_id VARCHAR(22) NOT NULL,
    checkin_timestamp TIMESTAMP NOT NULL,
    PRIMARY KEY(business_id, checkin_timestamp),
    FOREIGN KEY (business_id) REFERENCES "Business"(business_id)
);

CREATE TABLE "BusinessCategory" (
    business_id VARCHAR(22) NOT NULL,
    category_name TEXT NOT NULL,
    PRIMARY KEY(business_id, category_name),
    FOREIGN KEY (business_id) REFERENCES "Business"(business_id),
    FOREIGN KEY (category_name) REFERENCES "Category"(category_name)
);

CREATE TABLE "BusinessAttribute" (
    business_id VARCHAR(22) NOT NULL,
    attribute_name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY(business_id, attribute_name),
    FOREIGN KEY (business_id) REFERENCES "Business"(business_id),
    FOREIGN KEY (attribute_name) REFERENCES "Attribute"(attribute_name)
);

CREATE TABLE "BusinessHours" (
    business_id VARCHAR(22) NOT NULL,
    day_of_week TEXT NOT NULL,
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    PRIMARY KEY(business_id, day_of_week),
    FOREIGN KEY (business_id) REFERENCES "Business"(business_id)
); 