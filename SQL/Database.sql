CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS HotelChain CASCADE;
CREATE TABLE HotelChain (
 chain_id SERIAL PRIMARY KEY,
 chain_name VARCHAR (255) NOT NULL,
 num_hotels INT DEFAULT 0 NOT NULL,
 email VARCHAR(255) NOT NULL,
 street_number INT NOT NULL,
 street_name VARCHAR(255) NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 CONSTRAINT street_number CHECK (street_number > 0),
 CONSTRAINT num_hotels CHECK (num_hotels >= 0)
);

DROP TABLE IF EXISTS ChainPhoneNumber CASCADE;
CREATE TABLE ChainPhoneNumber(
    chain_id INT NOT NULL REFERENCES HotelChain(chain_id) ON DELETE CASCADE,
    phone_number VARCHAR(255) NOT NULL,
    PRIMARY KEY(chain_id, phone_number)
);

DROP TABLE IF EXISTS Hotel CASCADE;
CREATE TABLE Hotel (
 hotel_id SERIAL PRIMARY KEY,
 chain_id INTEGER NOT NULL REFERENCES HotelChain(chain_id) ON DELETE CASCADE,
 category INT NOT NULL,
 num_rooms INT DEFAULT 0 NOT NULL,
 email VARCHAR(255) NOT NULL,
 street_number INT NOT NULL,
 street_name VARCHAR(255) NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 CONSTRAINT street_number check (street_number > 0),
 CONSTRAINT categoryabove check (category >= 1),
 CONSTRAINT categorybelow check (category <= 5)
);

DROP TABLE IF EXISTS HotelPhoneNumber CASCADE;
CREATE TABLE HotelPhoneNumber(
    hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
    phone_number VARCHAR(255) NOT NULL,
    PRIMARY KEY(hotel_id, phone_number)
);

DROP TABLE IF EXISTS Room CASCADE;
CREATE TABLE Room(
  room_id SERIAL PRIMARY KEY,
  room_number INT NOT NULL,
  hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
  price INT NOT NULL,
  capacity INT NOT NULL,
  sea_view BOOLEAN NOT NULL,
  mountain_view BOOLEAN NOT NULL,
  damages BOOLEAN NOT NULL,
  can_be_extended BOOLEAN NOT NULL,
  CONSTRAINT room_number CHECK (room_number > 0),
  CONSTRAINT price CHECK (price >= 0),
  CONSTRAINT capacity CHECK (capacity > 0)
);

DROP TABLE IF EXISTS Amenity CASCADE;
CREATE TABLE Amenity(
    room_id INT NOT NULL REFERENCES Room(room_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    PRIMARY KEY(room_id, name)
);

DROP TABLE IF EXISTS Employee CASCADE;
CREATE TABLE Employee (
 SSN INT PRIMARY KEY,
 name VARCHAR (255) NOT NULL,
 hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
 street_number INT NOT NULL,
 street_name VARCHAR(255) NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 password VARCHAR(255) NOT NULL,
 CONSTRAINT street_number CHECK (street_number > 0),
 CONSTRAINT password CHECK (char_length(password) >= 5)
);

DROP TABLE IF EXISTS Manages CASCADE;
CREATE TABLE Manages(
 SSN INT NOT NULL REFERENCES Employee(SSN) ON DELETE CASCADE,
 hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
 PRIMARY KEY(SSN, hotel_id)
);

DROP TABLE IF EXISTS Role CASCADE;
CREATE TABLE Role(
 role_id SERIAL PRIMARY KEY,
 name VARCHAR(255) NOT NULL,
 description VARCHAR(255)
);

DROP TABLE IF EXISTS EmployeeRole CASCADE;
CREATE TABLE EmployeeRole(
 employee_ssn INT NOT NULL REFERENCES Employee(SSN) ON DELETE CASCADE,
 role_id INT NOT NULL REFERENCES Role(role_id) ON DELETE CASCADE,
 PRIMARY KEY(employee_ssn, role_id)
);

DROP TABLE IF EXISTS Customer CASCADE;
CREATE TABLE Customer(
    SSN INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    unit VARCHAR(255),
    city VARCHAR(255) NOT NULL,
    province VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    zip VARCHAR(255) NOT NULL,
    registration_date TIMESTAMP DEFAULT NOW() NOT NULL,
    password VARCHAR(255) NOT NULL,
    CONSTRAINT street_number CHECK (street_number > 0),
     CONSTRAINT password CHECK (char_length(password) >= 5)
);

DROP TABLE IF EXISTS BookingRental CASCADE;
CREATE TABLE BookingRental(
    booking_id SERIAL PRIMARY KEY,
    reservation_date TIMESTAMP NOT NULL,
    check_in_date TIMESTAMP NOT NULL,
    check_out_date TIMESTAMP NOT NULL,
    checked_in BOOLEAN DEFAULT FALSE NOT NULL,
    paid BOOLEAN DEFAULT FALSE NOT NULL,
    room_id INT NOT NULL REFERENCES Room(room_id) ON DELETE CASCADE,
    customer_ssn INT NOT NULL REFERENCES Customer(SSN) ON DELETE CASCADE,
    employee_ssn INT REFERENCES Employee(SSN) ON DELETE CASCADE,
    CONSTRAINT booking_id CHECK (booking_id > 0),
    CONSTRAINT dates1 CHECK (check_in_date<check_out_date),
    CONSTRAINT dates2 CHECK (reservation_date<=check_in_date),
    CONSTRAINT overlapping EXCLUDE USING gist (tsrange(check_in_date, check_out_date) WITH &&, room_id WITH =)
);


DROP TABLE IF EXISTS Archive CASCADE;
CREATE TABLE Archive (
    archive_id INT PRIMARY KEY,
    room_number INT NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    unit VARCHAR(255),
    hotel_city VARCHAR(255) NOT NULL,
    hotel_province VARCHAR(255) NOT NULL,
    hotel_zip VARCHAR(255) NOT NULL,
    hotel_country VARCHAR(255) NOT NULL,
    check_in_date TIMESTAMP NOT NULL,
    hotel_chain_name VARCHAR(255) NOT NULL,
    reservation_date TIMESTAMP,
    check_out_date TIMESTAMP NOT NULL,
    checked_in BOOLEAN NOT NULL,
    paid BOOLEAN DEFAULT FALSE NOT NULL,
    customer_ssn INT NOT NULL,
    employee_ssn INT,
    CONSTRAINT archive_id CHECK (archive_id > 0),
    CONSTRAINT street_number CHECK (street_number > 0),
    CONSTRAINT room_number CHECK (room_number > 0)
);

CREATE OR REPLACE FUNCTION archive_data() RETURNS TRIGGER AS $archive$
	BEGIN INSERT INTO Archive(archive_id, room_number, street_number, street_name, unit, hotel_city, hotel_province, hotel_country, 
        hotel_zip, check_in_date, hotel_chain_name, reservation_date, check_out_date, customer_ssn, employee_ssn, checked_in, paid)
            SELECT B.booking_id as archive_id,
                R.room_number, 
                H.street_number,
                H.street_name,
                H.unit,
                H.city,
                H.province,
                H.country,
                H.zip,
                B.check_in_date,
                HC.chain_name,
                B.reservation_date,
                B.check_out_date,
                B.customer_ssn,
                B.employee_ssn,
                B.checked_in,
				B.paid
            FROM Room R, 
                Hotel H, 
                HotelChain HC, 
                BookingRental B
            WHERE NEW.booking_id = B.booking_id AND
                B.room_id = R.room_id AND
                R.hotel_id = H.hotel_id AND
                H.chain_id = HC.chain_id;
			RETURN NULL;
	END;
$archive$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_archive() RETURNS TRIGGER AS $update_archive$
    BEGIN UPDATE Archive
        SET checked_in = subquery.checked_in,
            paid = subquery.paid,
            employee_ssn = subquery.employee_ssn,
            check_in_date = subquery.check_in_date,
            check_out_date = subquery.check_out_date,
            room_number = subquery.room_number
        FROM (SELECT R.room_number, 
                B.check_in_date,
                B.check_out_date,
                B.employee_ssn,
                B.checked_in,
				B.paid
            FROM Room R, 
                BookingRental B
            WHERE NEW.booking_id = B.booking_id AND
                B.room_id = R.room_id) as subquery
        WHERE Archive.archive_id = NEW.booking_id;
        RETURN NULL;
    END;
$update_archive$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inc_room() RETURNS TRIGGER AS $inc_room$
    BEGIN UPDATE Hotel
        SET num_rooms = num_rooms + 1
        WHERE hotel_id = NEW.hotel_id;
    RETURN NULL;
    END;
$inc_room$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dec_room() RETURNS TRIGGER AS $dec_room$
    BEGIN UPDATE Hotel
        SET num_rooms = num_rooms - 1
        WHERE hotel_id = NEW.hotel_id;
    RETURN NULL;
    END;
$dec_room$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inc() RETURNS TRIGGER AS $inc$
	BEGIN UPDATE HotelChain 
		SET num_hotels = num_hotels + 1 
		WHERE chain_id = NEW.chain_id;
    RETURN NULL;
	END; 
$inc$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decr() RETURNS TRIGGER AS $decr$
    BEGIN UPDATE HotelChain
        SET num_hotels = num_hotels - 1
        WHERE chain_id = OLD.chain_id;
    RETURN NULL;
    END;
$decr$ LANGUAGE plpgsql;
		
DROP TRIGGER IF EXISTS add_archive ON BookingRental;
CREATE TRIGGER add_archive 
    AFTER INSERT ON BookingRental 
	FOR EACH ROW
	EXECUTE FUNCTION archive_data();		

DROP TRIGGER IF EXISTS update_archive ON BookingRental;
CREATE TRIGGER update_archive
    AFTER UPDATE ON BookingRental
    FOR EACH ROW
    EXECUTE FUNCTION update_archive();

DROP TRIGGER IF EXISTS increment ON Hotel;
CREATE TRIGGER increment 
    AFTER INSERT ON Hotel 
	FOR EACH ROW
	EXECUTE FUNCTION inc();

DROP TRIGGER IF EXISTS decrement ON Hotel;
CREATE TRIGGER decrement
    AFTER DELETE ON Hotel
    FOR EACH ROW
    EXECUTE FUNCTION decr();

DROP TRIGGER IF EXISTS inc_rooms ON Room;
CREATE TRIGGER inc_rooms
    AFTER INSERT ON Room
    FOR EACH ROW
    EXECUTE FUNCTION inc_room();

DROP TRIGGER IF EXISTS dec_rooms ON Room;
CREATE TRIGGER dec_roooms
    AFTER DELETE ON Room
    FOR EACH ROW
    EXECUTE FUNCTION dec_room();DROP VIEW IF EXISTS employeeroles;
CREATE VIEW employeeroles AS
  SELECT r.role_id, er.employee_ssn as ssn, r.name, r.description
   FROM Role r
     INNER JOIN EmployeeRole er ON r.role_id = er.role_id ;

DROP VIEW IF EXISTS bookinginfo;
CREATE VIEW bookinginfo as
  SELECT br.booking_id, br.reservation_date, br.check_in_date, br.check_out_date, br.checked_in, br.paid, 
  r.room_number, hc.chain_name, h.hotel_id, h.street_number, h.street_name, h.unit, h.city, h.province, h.country, h.zip, br.employee_ssn,
  br.customer_ssn
  FROM BookingRental br
  INNER JOIN Room r on br.room_id = r.room_id
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id
  INNER JOIN HotelChain hc on h.chain_id = hc.chain_id;

DROP VIEW IF EXISTS roomarea2;
CREATE VIEW roomarea2 AS
  SELECT r.room_number, r.room_id, hc.chain_name, h.hotel_id, h.street_number, h.street_name, h.unit, h.city, h.province, h.country
  FROM Room r
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id
  INNER JOIN HotelChain hc on h.chain_id = hc.chain_id;


DROP VIEW IF EXISTS roomarea;
CREATE VIEW roomarea AS
  SELECT r.room_id, r.damages, h.city, h.province, h.country
  FROM Room r
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id;

  
DROP VIEW IF EXISTS roomcapacity;
CREATE VIEW roomcapacity AS
  SELECT h.hotel_id, r.room_id, r.room_number, r.capacity, r.can_be_extended
  FROM Hotel h, Room r
  WHERE r.hotel_id = h.hotel_id;

DROP VIEW IF EXISTS roominfo;
CREATE VIEW roominfo AS
  SELECT r.room_id,
    r.room_number,
    r.capacity,
    r.price,
    r.can_be_extended,
    r.sea_view,
    r.mountain_view,
    r.damages,
    h.category,
    h.street_number,
    h.street_name,
    h.unit,
    h.city,
    h.province,
    h.country,
    h.zip,
    hc.chain_name,
    h.num_rooms
  FROM Hotel h, Room r, HotelChain hc
  WHERE h.hotel_id = r.hotel_id AND
    hc.chain_id = h.chain_id; INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 1', 'hotel1@hotels.com', 179, 'Pine Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel1@hotels1.com', 30, 'Elm Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 1, 49.17, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 1, 46.67, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 1, 40.83, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 1, 36.67, 2, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (65, 1, 43.33, 3, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (1, 'David Rogers', 1, 271, 'Third Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (1, 1);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Mary Price', 1, 335, 'Oak Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (3, 'Sarah Rogers', 1, 126, 'Metcalfe Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (4, 'Emily Jones', 1, 249, 'Elm Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Paul Sanchez', 1, 333, 'Bay Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Susan Hernandez', 116, 'Elm Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', false, 5, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', false, 2, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', false, 3, 6);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Ashley Reed', 353, 'Laurier Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '113 DAY', false, 1, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', false, 1, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '161 DAY', false, 2, 7);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Meg Johnson', 320, 'Third Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '181 DAY', false, 5, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', false, 4, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', false, 2, 8);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel2@hotels1.com', 154, 'Laurier Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 2, 80.00, 4, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 2, 85.00, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 2, 93.33, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 2, 88.33, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 2, 68.33, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Ashley Miller', 2, 189, 'Main Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (9, 2);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Jon Ward', 2, 370, 'Main Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Natalia Jones', 2, 259, 'Bay Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (12, 'Emily Stewart', 2, 208, 'Willow Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Meg Johnson', 2, 127, 'First Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (14, 'David Hernandez', 31, 'Main Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '132 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', false, 8, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '50 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', false, 7, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', false, 5, 14);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Jon Davis', 112, 'Pine Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '183 DAY', false, 5, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 6, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '18 DAY', false, 10, 15);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Nick Cook', 29, 'Main Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 9, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '21 DAY', false, 6, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '28 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '33 DAY', false, 9, 16);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel3@hotels1.com', 95, 'Oak Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 3, 145.00, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 3, 120.00, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 3, 112.50, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 3, 140.00, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 3, 115.00, 3, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Jon Jones', 3, 388, 'Willow Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (17, 3);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Ashley Sanchez', 3, 332, 'Bank Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Elizabeth Miller', 3, 395, 'Laurier Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (20, 'Meg Brown', 3, 155, 'Bank Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Emily Johnson', 3, 355, 'Elm Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Sarah Hernandez', 394, 'First Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', false, 7, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '208 DAY', false, 15, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', false, 6, 22);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Susan Young', 228, 'Laurier Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', false, 10, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', false, 3, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', false, 4, 23);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Sarah Hernandez', 391, 'First Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '67 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '73 DAY', false, 14, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '60 DAY', false, 8, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '111 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '112 DAY', false, 4, 24);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 4, 'hotel4@hotels1.com', 267, 'Laurier Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 4, 193.33, 6, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 4, 146.67, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 4, 176.67, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 4, 200.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 4, 173.33, 5, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (25, 'Hudi Johnson', 4, 365, 'Bank Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (25, 4);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Ryan Sanchez', 4, 159, 'Bay Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Jon Brown', 4, 16, 'Second Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Emily Young', 4, 366, 'Bank Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Emily Wood', 4, 81, 'Pine Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (30, 'Ivana Wilson', 66, 'Willow Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', false, 11, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', false, 16, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '80 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', false, 8, 30);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Susan Stewart', 324, 'Oak Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '137 DAY', false, 7, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', false, 17, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '25 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', false, 1, 31);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Ashley Hernandez', 395, 'Bank Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '96 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', false, 11, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '174 DAY', false, 4, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', false, 6, 32);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 5, 'hotel5@hotels1.com', 228, 'Elm Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 5, 208.33, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 5, 183.33, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 5, 166.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 5, 166.67, 3, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 5, 166.67, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (33, 'David Cook', 5, 137, 'Second Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (33, 5);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (34, 'Liam Miller', 5, 54, 'Elm Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (35, 'Alex Cook', 5, 98, 'Second Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Meg Perez', 5, 60, 'Pine Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Nick Ward', 5, 191, 'Second Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Sahil Miller', 313, 'Third Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', false, 1, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '89 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 21, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '163 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', false, 24, 38);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (39, 'Andrew Ward', 352, 'Oak Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '44 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', false, 13, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', false, 2, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', false, 24, 39);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (40, 'Natalia Cook', 352, 'Main Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '113 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', false, 10, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', false, 16, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 25, 40);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel6@hotels1.com', 259, 'First Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 6, 41.67, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 6, 38.33, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (82, 6, 45.83, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 6, 36.67, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 6, 45.00, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (41, 'Sahil Johnson', 6, 178, 'Pine Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (41, 6);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Nick Rogers', 6, 89, 'First Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Elizabeth Smith', 6, 284, 'First Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Hudi Davis', 6, 242, 'First Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Hudi Reed', 6, 153, 'Third Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Alex Reed', 178, 'Elm Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '41 DAY', false, 13, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', false, 17, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 24, 46);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Ryan Jones', 12, 'Main Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '145 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', false, 18, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 15, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '143 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', false, 9, 47);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Sahil Miller', 181, 'Elm Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 18, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '196 DAY', false, 28, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '145 DAY', false, 18, 48);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel7@hotels1.com', 234, 'Laurier Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 7, 66.67, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 7, 100.00, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 7, 93.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (7, 7, 71.67, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 7, 68.33, 6, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Sarah Price', 7, 275, 'Oak Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (49, 7);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Susan Ward', 7, 186, 'Bank Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (51, 'Meg Perez', 7, 220, 'Bank Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (52, 'Ryan Brown', 7, 94, 'Second Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Andrew Price', 7, 70, 'Metcalfe Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Ivana Davis', 18, 'Elm Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', false, 8, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '188 DAY', false, 31, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '192 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', false, 7, 54);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (55, 'Hudi Wilson', 164, 'Bank Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '165 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', false, 2, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 20, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '142 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', false, 7, 55);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Liam Wilson', 324, 'Bank Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '82 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', false, 16, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '18 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 25, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '175 DAY', false, 17, 56);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel8@hotels1.com', 70, 'Oak Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 8, 112.50, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 8, 115.00, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 8, 130.00, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 8, 102.50, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 8, 112.50, 3, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Alex Price', 8, 374, 'Metcalfe Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (57, 8);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Meg Davis', 8, 168, 'First Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Hudi Wilson', 8, 388, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (60, 'David Williams', 8, 204, 'Pine Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (61, 'Mary Wood', 8, 291, 'Second Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (62, 'Sahil Ward', 31, 'First Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '204 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', false, 1, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '83 DAY', false, 33, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '46 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', false, 39, 62);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (63, 'Natalia Sanchez', 109, 'Main Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', false, 31, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', false, 14, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '108 DAY', false, 12, 63);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (64, 'Mary Jones', 95, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', false, 17, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '151 DAY', false, 5, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '66 DAY', false, 12, 64);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 2', 'hotel2@hotels.com', 188, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel1@hotels2.com', 290, 'Pine Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 9, 45.83, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 9, 33.33, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 9, 38.33, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 9, 44.17, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 9, 39.17, 2, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Alex Reed', 9, 147, 'First Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (65, 9);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (66, 'Alex Rogers', 9, 201, 'Third Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Andrew Smith', 9, 200, 'Elm Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (68, 'Natalia Price', 9, 170, 'Bank Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Natalia Smith', 9, 388, 'Pine Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (70, 'Paul Reed', 255, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', false, 44, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '198 DAY', false, 10, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '24 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', false, 38, 70);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Sarah Smith', 195, 'First Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '55 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', false, 4, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '110 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '112 DAY', false, 45, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', false, 36, 71);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Bob Price', 310, 'Metcalfe Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '65 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '67 DAY', false, 4, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', false, 4, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', false, 21, 72);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel2@hotels2.com', 105, 'Bay Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 10, 88.33, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 10, 98.33, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 10, 100.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 10, 98.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 10, 71.67, 4, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Paul Brown', 10, 204, 'Third Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (73, 10);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Andrew Cook', 10, 232, 'Elm Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Liam Wilson', 10, 96, 'Willow Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Ryan Ward', 10, 49, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (77, 'David Jones', 10, 68, 'Willow Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (78, 'Susan Cook', 289, 'Pine Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', false, 14, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', false, 41, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '213 DAY', false, 39, 78);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Emily Rogers', 109, 'Main Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', false, 16, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 33, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', false, 19, 79);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Emily Smith', 82, 'Third Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '154 DAY', false, 27, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '146 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', false, 29, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 7, 80);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel3@hotels2.com', 109, 'Oak Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 11, 130.00, 5, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 11, 125.00, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 11, 117.50, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 11, 117.50, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 11, 127.50, 5, true, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Paul Davis', 11, 51, 'Laurier Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (81, 11);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Jon Perez', 11, 95, 'Metcalfe Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Mary Price', 11, 347, 'First Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Paul Brown', 11, 314, 'Metcalfe Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Elizabeth Williams', 11, 2, 'Metcalfe Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Susan Sanchez', 104, 'Laurier Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '161 DAY', false, 36, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '69 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 53, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', false, 40, 86);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (87, 'Nick Ward', 205, 'First Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '81 DAY', false, 18, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', false, 49, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 54, 87);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (88, 'Paul Hernandez', 349, 'First Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', false, 15, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '183 DAY', false, 47, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', false, 27, 88);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 4, 'hotel4@hotels2.com', 16, 'Oak Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 12, 176.67, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 12, 133.33, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 12, 180.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 12, 183.33, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 12, 146.67, 3, false, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Nick Wood', 12, 319, 'Pine Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (89, 12);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Hudi Reed', 12, 312, 'Elm Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Nick Smith', 12, 285, 'Willow Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Meg Rogers', 12, 118, 'Willow Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Meg Price', 12, 370, 'Bank Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (94, 'Paul Williams', 268, 'Main Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', false, 35, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', false, 44, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', false, 35, 94);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Mary Sanchez', 101, 'Bank Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', false, 47, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '28 DAY', false, 40, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 16, 95);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Sahil Stewart', 16, 'Bay Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '200 DAY', false, 4, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '31 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '38 DAY', false, 37, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '132 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '136 DAY', false, 28, 96);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 5, 'hotel5@hotels2.com', 75, 'Third Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 13, 237.50, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 13, 229.17, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 13, 250.00, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 13, 170.83, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 13, 204.17, 6, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Paul Smith', 13, 257, 'Pine Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (97, 13);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (98, 'Jon Sanchez', 13, 347, 'Willow Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Natalia Wilson', 13, 16, 'Oak Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Emily Johnson', 13, 171, 'Bay Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Ryan Price', 13, 385, 'Laurier Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (102, 'Mary Wilson', 374, 'Pine Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '83 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', false, 10, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', false, 1, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '5 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', false, 55, 102);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Natalia Davis', 149, 'Bank Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', false, 5, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 24, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '40 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '44 DAY', false, 56, 103);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Liam Sanchez', 165, 'Second Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', false, 48, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', false, 63, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', false, 34, 104);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel6@hotels2.com', 71, 'Third Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 14, 42.50, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 14, 41.67, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 14, 35.83, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 14, 50.00, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 14, 38.33, 3, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (105, 'Alex Davis', 14, 223, 'Oak Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (105, 14);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (106, 'Elizabeth Perez', 14, 34, 'Second Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Natalia Jones', 14, 387, 'Main Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Emily Stewart', 14, 11, 'Bank Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Bob Sanchez', 14, 33, 'Elm Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Ryan Stewart', 204, 'Third Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', false, 54, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 65, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '173 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', false, 56, 110);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (111, 'David Davis', 57, 'Pine Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 67, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 6, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '29 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '31 DAY', false, 52, 111);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Ivana Perez', 172, 'Elm Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', false, 46, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '169 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', false, 11, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '204 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', false, 49, 112);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel7@hotels2.com', 78, 'Laurier Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 15, 100.00, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 15, 68.33, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 15, 78.33, 5, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 15, 85.00, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 15, 81.67, 3, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Liam Davis', 15, 89, 'Bank Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (113, 15);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (114, 'Alex Sanchez', 15, 253, 'Third Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Alex Rogers', 15, 78, 'Main Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (116, 'Nick Williams', 15, 267, 'Oak Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (117, 'Susan Cook', 15, 15, 'Third Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Paul Davis', 268, 'First Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '2 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', false, 19, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '162 DAY', false, 35, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '50 DAY', false, 36, 118);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (119, 'Ryan Hernandez', 3, 'Elm Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', false, 70, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '61 DAY', false, 70, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '55 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', false, 56, 119);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Susan Sanchez', 227, 'Metcalfe Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 35, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '183 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', false, 52, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', false, 32, 120);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel8@hotels2.com', 12, 'Main Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (52, 16, 100.00, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 16, 130.00, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 16, 130.00, 2, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 16, 150.00, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 16, 102.50, 6, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (121, 'Natalia Cook', 16, 177, 'First Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (121, 16);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (122, 'Sahil Price', 16, 71, 'Elm Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (123, 'Liam Wilson', 16, 345, 'Pine Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (124, 'Andrew Jones', 16, 206, 'Bay Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (125, 'Susan Stewart', 16, 197, 'Second Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (126, 'Bob Brown', 105, 'Bank Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '35 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '37 DAY', false, 68, 126);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', false, 35, 126);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '162 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 49, 126);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (127, 'Nick Ward', 24, 'Bank Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', false, 30, 127);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', false, 30, 127);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '169 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', false, 37, 127);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (128, 'Emily Stewart', 212, 'First Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '50 DAY', false, 25, 128);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', false, 39, 128);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '181 DAY', false, 32, 128);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 3', 'hotel3@hotels.com', 169, 'Bank Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel1@hotels3.com', 94, 'Pine Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 17, 38.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 17, 40.83, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 17, 33.33, 3, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 17, 45.00, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 17, 35.83, 2, true, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (129, 'Ryan Price', 17, 249, 'Third Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (129, 17);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (130, 'Natalia Sanchez', 17, 68, 'Elm Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (131, 'Mary Young', 17, 303, 'First Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (132, 'Susan Stewart', 17, 167, 'First Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (133, 'Andrew Price', 17, 388, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (134, 'Bob Reed', 167, 'Bay Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '54 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '61 DAY', false, 15, 134);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '142 DAY', false, 3, 134);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '181 DAY', false, 51, 134);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (135, 'Liam Wilson', 169, 'Oak Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', false, 56, 135);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 74, 135);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '3 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 77, 135);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (136, 'Meg Wood', 123, 'Metcalfe Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', false, 17, 136);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', false, 5, 136);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '111 DAY', false, 30, 136);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel2@hotels3.com', 150, 'Willow Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 18, 93.33, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 18, 76.67, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 18, 88.33, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 18, 98.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 18, 66.67, 4, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (137, 'Sahil Smith', 18, 320, 'First Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (137, 18);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (138, 'Nick Miller', 18, 152, 'Main Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (139, 'Sarah Brown', 18, 181, 'First Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (140, 'Ryan Price', 18, 258, 'Laurier Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (141, 'Sahil Price', 18, 240, 'Pine Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (142, 'Hudi Hernandez', 46, 'Pine Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', false, 2, 142);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '107 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '111 DAY', false, 41, 142);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '200 DAY', false, 65, 142);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (143, 'Sahil Wood', 176, 'First Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '93 DAY', false, 57, 143);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '70 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', false, 45, 143);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '34 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '39 DAY', false, 31, 143);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (144, 'Emily Brown', 220, 'Main Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '183 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', false, 30, 144);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 85, 144);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', false, 54, 144);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel3@hotels3.com', 207, 'Main Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 19, 130.00, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 19, 110.00, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 19, 132.50, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 19, 150.00, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 19, 125.00, 6, false, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (145, 'Ivana Stewart', 19, 344, 'Oak Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (145, 19);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (146, 'Nick Hernandez', 19, 277, 'Bay Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (147, 'Alex Sanchez', 19, 173, 'Metcalfe Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (148, 'Liam Brown', 19, 3, 'First Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (149, 'Natalia Ward', 19, 203, 'Second Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (150, 'Alex Miller', 94, 'Willow Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', false, 34, 150);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '17 DAY', false, 62, 150);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 10, 150);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (151, 'Emily Smith', 137, 'Bay Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 14, 151);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', false, 95, 151);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', false, 93, 151);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (152, 'Nick Price', 187, 'Main Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '126 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '132 DAY', false, 64, 152);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '131 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', false, 44, 152);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '154 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', false, 88, 152);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 4, 'hotel4@hotels3.com', 71, 'Oak Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (14, 20, 150.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (68, 20, 156.67, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 20, 200.00, 3, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 20, 170.00, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 20, 173.33, 5, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (153, 'Susan Hernandez', 20, 186, 'First Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (153, 20);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (154, 'Bob Wilson', 20, 383, 'Bay Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (155, 'Sarah Stewart', 20, 39, 'Bank Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (156, 'Sahil Smith', 20, 158, 'Main Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (157, 'Sarah Price', 20, 284, 'Bank Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (158, 'Ivana Hernandez', 355, 'Bay Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', false, 31, 158);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '81 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', false, 44, 158);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '207 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '213 DAY', false, 12, 158);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (159, 'Bob Smith', 122, 'Elm Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', false, 25, 159);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '126 DAY', false, 32, 159);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', false, 99, 159);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (160, 'Mary Cook', 114, 'First Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 56, 160);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '137 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', false, 13, 160);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '115 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 39, 160);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 5, 'hotel5@hotels3.com', 130, 'Metcalfe Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 21, 245.83, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 21, 200.00, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 21, 191.67, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 21, 233.33, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 21, 191.67, 2, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (161, 'Liam Johnson', 21, 294, 'Bank Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (161, 21);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (162, 'Natalia Young', 21, 157, 'Bank Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (163, 'Nick Johnson', 21, 265, 'Pine Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (164, 'Elizabeth Smith', 21, 47, 'Elm Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (165, 'Sarah Wood', 21, 152, 'Main Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (166, 'Ryan Cook', 273, 'First Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', false, 85, 166);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', false, 88, 166);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '33 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '37 DAY', false, 60, 166);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (167, 'Sarah Cook', 351, 'Bay Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '98 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', false, 80, 167);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '145 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', false, 26, 167);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '173 DAY', false, 46, 167);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (168, 'Sarah Davis', 202, 'First Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 9, 168);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '54 DAY', false, 71, 168);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '208 DAY', false, 36, 168);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel6@hotels3.com', 225, 'Metcalfe Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 22, 47.50, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 22, 38.33, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 22, 46.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 22, 33.33, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 22, 46.67, 2, true, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (169, 'Ryan Davis', 22, 29, 'Bank Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (169, 22);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (170, 'Susan Young', 22, 376, 'Second Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (171, 'Sahil Davis', 22, 248, 'Pine Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (172, 'Mary Smith', 22, 314, 'Bank Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (173, 'Andrew Sanchez', 22, 383, 'Second Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (174, 'Hudi Stewart', 355, 'Bay Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '5 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', false, 16, 174);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '55 DAY', false, 96, 174);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '123 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '125 DAY', false, 63, 174);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (175, 'Natalia Davis', 8, 'Oak Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '32 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '39 DAY', false, 105, 175);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', false, 75, 175);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '60 DAY', false, 16, 175);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (176, 'Elizabeth Davis', 361, 'Oak Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', false, 97, 176);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '70 DAY', false, 93, 176);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', false, 1, 176);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel7@hotels3.com', 69, 'Oak Way', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 23, 68.33, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 23, 78.33, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 23, 88.33, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 23, 90.00, 5, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 23, 100.00, 4, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (177, 'Elizabeth Young', 23, 381, 'Main Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (177, 23);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (178, 'Emily Cook', 23, 193, 'Laurier Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (179, 'Bob Price', 23, 336, 'Oak Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (180, 'Sarah Johnson', 23, 353, 'Bank Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (181, 'Bob Price', 23, 126, 'Elm Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (182, 'Ryan Hernandez', 312, 'Second Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', false, 25, 182);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '35 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '41 DAY', false, 84, 182);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '188 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', false, 44, 182);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (183, 'David Young', 156, 'Bay Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', false, 43, 183);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '162 DAY', false, 86, 183);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '100 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', false, 41, 183);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (184, 'Elizabeth Miller', 11, 'First Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '151 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', false, 48, 184);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '69 DAY', false, 56, 184);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '27 DAY', false, 14, 184);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel8@hotels3.com', 285, 'Elm Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 24, 100.00, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 24, 140.00, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 24, 142.50, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 24, 122.50, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 24, 107.50, 4, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (185, 'Mary Davis', 24, 339, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (185, 24);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (186, 'Sahil Rogers', 24, 386, 'Pine Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (187, 'Ashley Wood', 24, 308, 'Second Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (188, 'Jon Rogers', 24, 381, 'Oak Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (189, 'Bob Ward', 24, 335, 'Second Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (190, 'Elizabeth Stewart', 15, 'Main Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '147 DAY', false, 76, 190);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '197 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '203 DAY', false, 39, 190);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', false, 30, 190);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (191, 'Jon Sanchez', 47, 'Third Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', false, 71, 191);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', false, 111, 191);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', false, 19, 191);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (192, 'Paul Brown', 211, 'Bank Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '54 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '60 DAY', false, 32, 192);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '93 DAY', false, 51, 192);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '146 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', false, 32, 192);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 4', 'hotel4@hotels.com', 13, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel1@hotels4.com', 92, 'Pine Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 25, 47.50, 5, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 25, 40.00, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 25, 48.33, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 25, 39.17, 5, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 25, 35.83, 5, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (193, 'Elizabeth Johnson', 25, 139, 'First Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (193, 25);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (194, 'Ashley Hernandez', 25, 197, 'Second Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (195, 'Bob Rogers', 25, 248, 'First Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (196, 'Liam Reed', 25, 185, 'Second Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (197, 'Ivana Rogers', 25, 52, 'Second Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (198, 'Liam Cook', 144, 'First Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '3 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', false, 106, 198);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 124, 198);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', false, 77, 198);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (199, 'Hudi Jones', 72, 'Second Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '2 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', false, 82, 199);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', false, 10, 199);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '125 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '126 DAY', false, 42, 199);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (200, 'Liam Hernandez', 193, 'Bank Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', false, 46, 200);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', false, 90, 200);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '181 DAY', false, 99, 200);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel2@hotels4.com', 10, 'Bank Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 26, 88.33, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 26, 98.33, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 26, 83.33, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 26, 86.67, 2, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 26, 96.67, 2, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (201, 'Nick Cook', 26, 383, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (201, 26);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (202, 'Alex Miller', 26, 185, 'Third Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (203, 'Ryan Jones', 26, 148, 'Bank Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (204, 'Ashley Wilson', 26, 127, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (205, 'Andrew Rogers', 26, 378, 'Third Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (206, 'Meg Jones', 278, 'Bank Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '209 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '214 DAY', false, 104, 206);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '39 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', false, 112, 206);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '139 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '143 DAY', false, 58, 206);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (207, 'Ryan Young', 165, 'First Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 108, 207);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '136 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '143 DAY', false, 113, 207);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '147 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', false, 6, 207);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (208, 'Hudi Jones', 170, 'Laurier Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', false, 57, 208);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '21 DAY', false, 10, 208);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '212 DAY', false, 87, 208);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel3@hotels4.com', 1, 'Main Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 27, 142.50, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 27, 112.50, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 27, 125.00, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 27, 135.00, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 27, 120.00, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (209, 'Bob Johnson', 27, 300, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (209, 27);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (210, 'Elizabeth Jones', 27, 156, 'Oak Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (211, 'Nick Miller', 27, 306, 'Bank Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (212, 'Ryan Williams', 27, 4, 'Second Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (213, 'Elizabeth Price', 27, 5, 'Laurier Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (214, 'Mary Brown', 272, 'Pine Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', false, 92, 214);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', false, 15, 214);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', false, 102, 214);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (215, 'Andrew Cook', 305, 'Main Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', false, 36, 215);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '74 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '77 DAY', false, 41, 215);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 90, 215);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (216, 'Nick Perez', 390, 'Bank Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', false, 106, 216);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', false, 65, 216);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '33 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '35 DAY', false, 115, 216);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 4, 'hotel4@hotels4.com', 151, 'Oak Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 28, 186.67, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 28, 153.33, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 28, 146.67, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 28, 136.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 28, 133.33, 2, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (217, 'Elizabeth Hernandez', 28, 76, 'Willow Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (217, 28);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (218, 'Elizabeth Jones', 28, 306, 'Willow Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (219, 'Sarah Reed', 28, 44, 'Metcalfe Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (220, 'Andrew Sanchez', 28, 124, 'Metcalfe Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (221, 'Ashley Stewart', 28, 5, 'Willow Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (222, 'Susan Wood', 161, 'Bank Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '151 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', false, 33, 222);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '25 DAY', false, 128, 222);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '200 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', false, 26, 222);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (223, 'Paul Hernandez', 319, 'Laurier Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', false, 36, 223);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '70 DAY', false, 137, 223);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '41 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', false, 101, 223);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (224, 'Hudi Miller', 6, 'Elm Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '175 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', false, 49, 224);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', false, 139, 224);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '197 DAY', false, 73, 224);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 5, 'hotel5@hotels4.com', 277, 'Third Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (33, 29, 187.50, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (14, 29, 212.50, 3, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 29, 170.83, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 29, 204.17, 4, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 29, 195.83, 3, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (225, 'Bob Brown', 29, 301, 'Bay Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (225, 29);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (226, 'Paul Rogers', 29, 350, 'First Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (227, 'Nick Perez', 29, 371, 'Second Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (228, 'Sahil Hernandez', 29, 164, 'Bay Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (229, 'Meg Miller', 29, 274, 'Main Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (230, 'David Jones', 333, 'Elm Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '128 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', false, 22, 230);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', false, 102, 230);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '29 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', false, 138, 230);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (231, 'Andrew Brown', 334, 'Metcalfe Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', false, 37, 231);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '211 DAY', false, 141, 231);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', false, 135, 231);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (232, 'Ashley Cook', 87, 'Main Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '110 DAY', false, 140, 232);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '188 DAY', false, 130, 232);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', false, 111, 232);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel6@hotels4.com', 2, 'Third Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (26, 30, 45.83, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 30, 43.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 30, 39.17, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 30, 40.83, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 30, 49.17, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (233, 'Jon Stewart', 30, 66, 'Bank Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (233, 30);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (234, 'Alex Wilson', 30, 196, 'Second Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (235, 'Ivana Sanchez', 30, 264, 'Pine Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (236, 'Andrew Young', 30, 21, 'Pine Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (237, 'Elizabeth Wilson', 30, 230, 'Oak Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (238, 'Sahil Johnson', 1, 'Second Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '46 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '48 DAY', false, 70, 238);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 86, 238);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', false, 132, 238);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (239, 'Andrew Jones', 88, 'Bank Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '203 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', false, 82, 239);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '34 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '39 DAY', false, 48, 239);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '100 DAY', false, 146, 239);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (240, 'Alex Wilson', 368, 'Bank Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '96 DAY', false, 128, 240);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '107 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 58, 240);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '65 DAY', false, 141, 240);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel7@hotels4.com', 91, 'Metcalfe Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 31, 98.33, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 31, 86.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 31, 93.33, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 31, 96.67, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 31, 91.67, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (241, 'Alex Sanchez', 31, 126, 'Main Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (241, 31);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (242, 'David Hernandez', 31, 19, 'Bay Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (243, 'Liam Sanchez', 31, 289, 'Laurier Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (244, 'Ryan Brown', 31, 232, 'First Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (245, 'Susan Sanchez', 31, 353, 'Laurier Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (246, 'Ryan Reed', 268, 'First Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 60, 246);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '65 DAY', false, 106, 246);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '74 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '80 DAY', false, 150, 246);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (247, 'Alex Cook', 20, 'Metcalfe Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '151 DAY', false, 67, 247);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '27 DAY', false, 17, 247);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '77 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '78 DAY', false, 24, 247);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (248, 'Jon Sanchez', 309, 'Third Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', false, 110, 248);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 142, 248);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '196 DAY', false, 121, 248);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel8@hotels4.com', 271, 'Laurier Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 32, 122.50, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 32, 115.00, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 32, 102.50, 4, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 32, 112.50, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (84, 32, 147.50, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (249, 'Emily Ward', 32, 98, 'Main Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (249, 32);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (250, 'Emily Reed', 32, 182, 'First Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (251, 'Elizabeth Cook', 32, 390, 'First Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (252, 'Nick Perez', 32, 256, 'Pine Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (253, 'Jon Wood', 32, 30, 'Third Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (254, 'Susan Young', 36, 'Bank Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '28 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '32 DAY', false, 29, 254);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '110 DAY', false, 74, 254);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', false, 119, 254);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (255, 'Natalia Williams', 207, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 3, 255);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '113 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '115 DAY', false, 31, 255);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', false, 109, 255);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (256, 'Hudi Reed', 374, 'Oak Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '53 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '55 DAY', false, 5, 256);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', false, 70, 256);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '22 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', false, 121, 256);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 5', 'hotel5@hotels.com', 107, 'Second Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel1@hotels5.com', 201, 'Metcalfe Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 33, 44.17, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 33, 45.83, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 33, 43.33, 3, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 33, 35.00, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 33, 34.17, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (257, 'Emily Smith', 33, 167, 'Bay Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (257, 33);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (258, 'Ivana Wood', 33, 114, 'Bay Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (259, 'Bob Cook', 33, 144, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (260, 'Natalia Johnson', 33, 353, 'Main Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (261, 'Sahil Smith', 33, 328, 'Second Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (262, 'Ivana Stewart', 326, 'Oak Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', false, 153, 262);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '196 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '202 DAY', false, 116, 262);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '42 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '48 DAY', false, 23, 262);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (263, 'Mary Rogers', 112, 'First Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', false, 81, 263);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '83 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', false, 50, 263);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', false, 152, 263);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (264, 'Nick Ward', 296, 'Metcalfe Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '204 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', false, 37, 264);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 152, 264);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 117, 264);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel2@hotels5.com', 224, 'Second Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (9, 34, 98.33, 5, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 34, 71.67, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 34, 83.33, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (9, 34, 71.67, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (65, 34, 83.33, 4, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (265, 'Ivana Davis', 34, 349, 'Bay Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (265, 34);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (266, 'Alex Stewart', 34, 29, 'Pine Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (267, 'Bob Reed', 34, 320, 'Metcalfe Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (268, 'Ryan Young', 34, 113, 'Elm Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (269, 'Natalia Perez', 34, 340, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (270, 'Elizabeth Cook', 222, 'Elm Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '87 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 73, 270);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', false, 102, 270);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '81 DAY', false, 93, 270);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (271, 'Ryan Stewart', 287, 'Willow Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', false, 110, 271);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '129 DAY', false, 164, 271);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', false, 16, 271);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (272, 'Jon Ward', 379, 'Metcalfe Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 108, 272);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', false, 160, 272);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '96 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', false, 35, 272);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel3@hotels5.com', 261, 'Pine Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 35, 132.50, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 35, 137.50, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 35, 100.00, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 35, 135.00, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 35, 105.00, 4, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (273, 'Sarah Williams', 35, 134, 'Elm Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (273, 35);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (274, 'Susan Davis', 35, 35, 'Main Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (275, 'Liam Johnson', 35, 366, 'Oak Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (276, 'Paul Davis', 35, 150, 'Laurier Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (277, 'Mary Stewart', 35, 269, 'Pine Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (278, 'Ryan Stewart', 398, 'Bay Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '44 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '48 DAY', false, 152, 278);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '123 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '128 DAY', false, 60, 278);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', false, 107, 278);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (279, 'Elizabeth Johnson', 139, 'Main Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', false, 23, 279);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', false, 33, 279);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '87 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', false, 153, 279);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (280, 'Bob Miller', 250, 'Pine Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', false, 34, 280);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '53 DAY', false, 5, 280);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '89 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', false, 64, 280);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 4, 'hotel4@hotels5.com', 23, 'First Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 36, 140.00, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 36, 163.33, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 36, 163.33, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 36, 190.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 36, 183.33, 2, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (281, 'Sarah Johnson', 36, 97, 'Laurier Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (281, 36);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (282, 'Mary Jones', 36, 101, 'Main Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (283, 'Elizabeth Stewart', 36, 117, 'Main Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (284, 'Ivana Rogers', 36, 258, 'Second Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (285, 'Meg Williams', 36, 107, 'Laurier Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (286, 'Sarah Reed', 103, 'Third Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '73 DAY', false, 73, 286);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', false, 79, 286);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '151 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', false, 22, 286);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (287, 'Emily Wood', 156, 'Elm Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', false, 119, 287);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '24 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '25 DAY', false, 77, 287);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '208 DAY', false, 81, 287);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (288, 'Paul Johnson', 190, 'Bay Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', false, 53, 288);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '197 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', false, 150, 288);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', false, 172, 288);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 5, 'hotel5@hotels5.com', 42, 'Laurier Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 37, 225.00, 6, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 37, 175.00, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 37, 187.50, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 37, 170.83, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 37, 212.50, 3, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (289, 'Elizabeth Reed', 37, 288, 'Second Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (289, 37);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (290, 'Meg Reed', 37, 256, 'Willow Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (291, 'Hudi Rogers', 37, 51, 'Second Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (292, 'Emily Stewart', 37, 78, 'First Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (293, 'Sahil Cook', 37, 263, 'Laurier Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (294, 'Elizabeth Young', 306, 'Elm Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '69 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 138, 294);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', false, 141, 294);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '65 DAY', false, 148, 294);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (295, 'Natalia Price', 216, 'Third Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', false, 9, 295);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '208 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '213 DAY', false, 116, 295);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '188 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', false, 51, 295);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (296, 'Jon Wood', 35, 'Metcalfe Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '107 DAY', false, 162, 296);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '123 DAY', false, 71, 296);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '125 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '126 DAY', false, 109, 296);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel6@hotels5.com', 78, 'Elm Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 38, 40.83, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 38, 45.83, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 38, 38.33, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 38, 40.00, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 38, 42.50, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (297, 'Alex Stewart', 38, 266, 'Laurier Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (297, 38);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (298, 'Nick Miller', 38, 168, 'Metcalfe Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (299, 'Hudi Williams', 38, 120, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (300, 'Sahil Perez', 38, 128, 'Elm Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (301, 'Alex Sanchez', 38, 324, 'Laurier Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (302, 'Natalia Cook', 86, 'Elm Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', false, 136, 302);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 166, 302);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '77 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '78 DAY', false, 52, 302);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (303, 'David Ward', 247, 'Elm Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', false, 151, 303);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', false, 61, 303);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 14, 303);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (304, 'Emily Stewart', 139, 'Second Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '73 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '78 DAY', false, 81, 304);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '143 DAY', false, 49, 304);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', false, 91, 304);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel7@hotels5.com', 292, 'Second Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (82, 39, 96.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 39, 71.67, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 39, 96.67, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 39, 98.33, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 39, 96.67, 4, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (305, 'Paul Reed', 39, 248, 'Metcalfe Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (305, 39);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (306, 'Sarah Stewart', 39, 151, 'Bay Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (307, 'Andrew Smith', 39, 368, 'Third Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (308, 'Elizabeth Wood', 39, 70, 'Elm Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (309, 'Hudi Sanchez', 39, 288, 'Main Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (310, 'Andrew Wilson', 223, 'Main Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '67 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', false, 181, 310);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', false, 78, 310);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '188 DAY', false, 189, 310);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (311, 'Paul Davis', 301, 'Third Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '215 DAY', false, 149, 311);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '131 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', false, 132, 311);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '146 DAY', false, 127, 311);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (312, 'Ryan Davis', 227, 'Third Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', false, 180, 312);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', false, 99, 312);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '77 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', false, 82, 312);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel8@hotels5.com', 131, 'Oak Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 40, 135.00, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 40, 112.50, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 40, 135.00, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (68, 40, 147.50, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 40, 105.00, 4, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (313, 'Hudi Williams', 40, 118, 'Metcalfe Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (313, 40);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (314, 'Sahil Miller', 40, 246, 'Bay Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (315, 'Sahil Brown', 40, 379, 'Oak Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (316, 'Ashley Reed', 40, 111, 'Bay Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (317, 'Sahil Ward', 40, 210, 'First Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (318, 'Liam Stewart', 230, 'Third Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', false, 104, 318);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '73 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', false, 4, 318);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', false, 197, 318);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (319, 'Sarah Rogers', 4, 'Main Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '112 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', false, 176, 319);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '21 DAY', false, 193, 319);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '140 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '147 DAY', false, 132, 319);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (320, 'Meg Brown', 339, 'Bay Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', false, 67, 320);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', false, 29, 320);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', false, 116, 320);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (59, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (101, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (154, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (185, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Air conditioner', NULL);
INSERT INTO Role(name, description) VALUES ('Custodian', NULL);
INSERT INTO Role(name, description) VALUES ('Maid', NULL);
INSERT INTO Role(name, description) VALUES ('Bellboy', NULL);
INSERT INTO Role(name, description) VALUES ('Front Desk Person', NULL);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (2, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (3, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (4, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (5, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (10, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (11, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (12, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (13, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (18, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (19, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (20, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (21, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (26, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (27, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (28, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (29, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (34, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (35, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (36, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (37, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (42, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (43, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (44, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (45, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (50, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (51, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (52, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (53, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (58, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (59, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (60, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (61, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (66, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (67, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (68, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (69, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (74, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (75, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (76, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (77, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (82, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (83, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (84, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (85, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (90, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (91, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (92, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (93, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (98, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (99, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (100, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (101, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (106, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (107, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (108, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (109, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (114, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (115, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (116, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (117, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (122, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (123, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (124, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (125, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (130, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (131, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (132, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (133, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (138, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (139, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (140, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (141, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (146, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (147, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (148, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (149, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (154, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (155, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (156, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (157, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (162, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (163, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (164, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (165, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (170, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (171, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (172, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (173, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (178, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (179, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (180, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (181, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (186, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (187, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (188, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (189, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (194, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (195, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (196, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (197, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (202, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (203, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (204, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (205, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (210, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (211, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (212, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (213, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (218, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (219, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (220, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (221, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (226, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (227, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (228, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (229, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (234, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (235, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (236, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (237, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (242, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (243, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (244, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (245, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (250, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (251, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (252, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (253, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (258, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (259, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (260, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (261, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (266, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (267, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (268, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (269, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (274, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (275, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (276, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (277, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (282, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (283, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (284, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (285, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (290, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (291, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (292, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (293, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (298, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (299, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (300, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (301, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (306, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (307, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (308, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (309, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (314, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (315, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (316, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (317, 1);
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (1, '5113815217');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (2, '3522043181');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (3, '8666025356');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (4, '4716034455');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (5, '5165968733');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (1, '6305513244');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (2, '9511970692');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (3, '1306199883');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (4, '8397644689');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (5, '9026643907');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (6, '4089844426');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (7, '1844608620');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (8, '3546863175');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (9, '4251399349');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (10, '4142782592');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (11, '4703405930');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (12, '5528605363');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (13, '3878103652');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (14, '1734148041');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (15, '7245540731');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (16, '9217760972');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (17, '3486052418');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (18, '2687676705');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (19, '2241943917');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (20, '5660221217');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (21, '5684412040');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (22, '1944947201');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (23, '2882176694');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (24, '4833512120');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (25, '5065582413');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (26, '3174304138');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (27, '1404622931');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (28, '8492533933');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (29, '6803446501');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (30, '4522957791');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (31, '3406769704');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (32, '5461980224');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (33, '2022410283');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (34, '4282498378');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (35, '9593196300');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (36, '8650411096');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (37, '4492942285');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (38, '3005994448');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (39, '7565988141');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (40, '5590373135');
