#!/usr/bin/env python3
import json
import psycopg2

def connect_to_db():
    try:
        conn = psycopg2.connect(
            dbname="ledgertestadem",
            user="adem",
            password="",  # leave empty if no password
            host="localhost"
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None

def insert_business(conn, cursor):
    with open('business.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            
            business_id = data.get('business_id')
            name = data.get('name')
            address = data.get('address')
            city = data.get('city')
            state = data.get('state')
            postal_code = data.get('postal_code')
            latitude = data.get('latitude')
            longitude = data.get('longitude')
            is_open = data.get('is_open')
            stars = data.get('stars')
            
            try:
                cursor.execute("""
                    INSERT INTO "Business" (
                        business_id, name, street_address, city, state, 
                        zipcode, latitude, longitude, is_open, star_rating, num_tips
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    business_id, name, address, city, state, 
                    postal_code, latitude, longitude, is_open, stars, 0
                ))
                
                # insert business hours if available
                if 'hours' in data:
                    hours = data.get('hours', {})
                    for day, time_range in hours.items():
                        if time_range is not None and ':' in time_range:
                            times = time_range.split('-')
                            if len(times) == 2:
                                open_time, close_time = times
                                cursor.execute("""
                                    INSERT INTO "BusinessHours" (
                                        business_id, day_of_week, open_time, close_time
                                    ) VALUES (%s, %s, %s, %s)
                                """, (business_id, day, open_time, close_time))
                
            except Exception as e:
                print(f"Error inserting business {business_id}: {e}")
                continue
                
    print("Finished inserting businesses")

def insert_category(conn, cursor):
    # First insert distinct categories
    with open('categories.json', 'r', encoding='utf-8') as f:
        unique_categories = set()
        for line in f:
            data = json.loads(line)
            categories = data.get('categories', [])
            for category in categories:
                unique_categories.add(category)
        
        for category in unique_categories:
            try:
                cursor.execute("""
                    INSERT INTO "Category" (category_name)
                    VALUES (%s)
                """, (category,))
            except Exception as e:
                print(f"Error inserting category {category}: {e}")
    
    # Now insert business-category relationships
    with open('categories.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            business_id = data.get('business_id')
            categories = data.get('categories', [])
            
            for category in categories:
                try:
                    cursor.execute("""
                        INSERT INTO "BusinessCategory" (business_id, category_name)
                        VALUES (%s, %s)
                    """, (business_id, category))
                except Exception as e:
                    print(f"Error linking business {business_id} to category {category}: {e}")
    
    print("Finished inserting categories")

def insert_attribute(conn, cursor):
    # First insert distinct attributes
    with open('attributes.json', 'r', encoding='utf-8') as f:
        unique_attributes = set()
        for line in f:
            data = json.loads(line)
            attributes = data.get('attributes', {})
            for attr_name in attributes.keys():
                unique_attributes.add(attr_name)
        
        for attr_name in unique_attributes:
            try:
                cursor.execute("""
                    INSERT INTO "Attribute" (attribute_name)
                    VALUES (%s)
                """, (attr_name,))
            except Exception as e:
                print(f"Error inserting attribute {attr_name}: {e}")
    
    # Now insert business-attribute relationships
    with open('attributes.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            business_id = data.get('business_id')
            attributes = data.get('attributes', {})
            
            for attr_name, attr_value in attributes.items():
                # Convert values to strings for storage
                if isinstance(attr_value, bool):
                    value_str = str(attr_value).lower()
                elif attr_value is None:
                    value_str = 'null'
                else:
                    value_str = str(attr_value)
                
                try:
                    cursor.execute("""
                        INSERT INTO "BusinessAttribute" (business_id, attribute_name, value)
                        VALUES (%s, %s, %s)
                    """, (business_id, attr_name, value_str))
                except Exception as e:
                    print(f"Error linking business {business_id} to attribute {attr_name}: {e}")
    
    print("Finished inserting attributes")

def insert_user(conn, cursor):
    with open('user.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            
            user_id = data.get('user_id')
            name = data.get('name')
            average_stars = data.get('average_stars')
            funny = data.get('funny', 0)
            useful = data.get('useful', 0)
            cool = data.get('cool', 0)
            fans = data.get('fans', 0)
            yelping_since = data.get('yelping_since')
            
            try:
                cursor.execute("""
                    INSERT INTO "User" (
                        user_id, name, average_stars, funny_score, useful_score,
                        cool_score, num_fans, tip_count, yelping_since
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    user_id, name, average_stars, funny, useful,
                    cool, fans, 0, yelping_since
                ))
            except Exception as e:
                print(f"Error inserting user {user_id}: {e}")
                continue
    
    print("Finished inserting users")

def insert_friendship(conn, cursor):
    with open('friend.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            
            user_id = data.get('user_id')
            friends = data.get('friends', [])
            
            for friend_id in friends:
                try:
                    cursor.execute("""
                        INSERT INTO "Friendship" (user_id, friend_id)
                        VALUES (%s, %s)
                    """, (user_id, friend_id))
                except Exception as e:
                    print(f"Error inserting friendship between {user_id} and {friend_id}: {e}")
                    continue
    
    print("Finished inserting friendships")

def insert_tip(conn, cursor):
    with open('tip.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            
            business_id = data.get('business_id')
            user_id = data.get('user_id')
            date = data.get('date')
            text = data.get('text')
            likes = data.get('likes', 0)
            
            try:
                cursor.execute("""
                    INSERT INTO "Tip" (business_id, user_id, tip_date, tip_text, likes)
                    VALUES (%s, %s, %s, %s, %s)
                """, (business_id, user_id, date, text, likes))
            except Exception as e:
                print(f"Error inserting tip by {user_id} for {business_id}: {e}")
                continue
    
    print("Finished inserting tips")

def insert_checkin(conn, cursor):
    with open('checkin.json', 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            
            business_id = data.get('business_id')
            checkin_dates = data.get('date', '').split(', ')
            
            for timestamp in checkin_dates:
                if timestamp:  # Only insert if timestamp is not empty
                    try:
                        cursor.execute("""
                            INSERT INTO "Checkin" (business_id, checkin_timestamp)
                            VALUES (%s, %s)
                        """, (business_id, timestamp))
                    except Exception as e:
                        print(f"Error inserting checkin at {timestamp} for {business_id}: {e}")
                        continue
    
    print("Finished inserting checkins")

def main():
    conn = connect_to_db()
    if not conn:
        print("Failed to connect to database. Exiting.")
        return
    
    cursor = conn.cursor()
    
    # Insert data in correct dependency order
    try:
        # Start by populating business and its direct dependencies
        insert_business(conn, cursor)
        insert_category(conn, cursor)
        insert_attribute(conn, cursor)
        
        # Then users and their relationships
        insert_user(conn, cursor)
        insert_friendship(conn, cursor)
        
        # Finally tips and checkins
        insert_tip(conn, cursor)
        insert_checkin(conn, cursor)
        
        # Commit all transactions at once
        conn.commit()
        print("All data inserted successfully!")
    
    except Exception as e:
        conn.rollback()
        print(f"Error during data insertion: {e}")
    
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    main() 