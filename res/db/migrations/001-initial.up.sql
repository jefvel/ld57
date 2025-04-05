
-- Rooms
CREATE TABLE IF NOT EXISTS rooms (
	id INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	identifier TEXT NOT NULL UNIQUE
);

-- Users with sessions
CREATE TABLE IF NOT EXISTS users (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	room_id INTEGER,
	session_id TEXT,
	username TEXT NOT NULL UNIQUE,
	x INT,
	y INT,

	total_online_time INTEGER DEFAULT 0,
	current_session_time INTEGER DEFAULT 0,
	last_sign_in_time INTEGER,

	last_timestamp INTEGER DEFAULT CURRENT_TIMESTAMP,

	data JSONB not null default '{}'
);

-- General events that happen
CREATE TABLE IF NOT EXISTS events (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	type TEXT not null,
	room_id INTEGER,
	timestamp INTEGER DEFAULT CURRENT_TIMESTAMP,
	user_id INT,
	data jsonb not null default '{}'
);

-- User saves
CREATE TABLE IF NOT EXISTS saves (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	username TEXT UNIQUE NOT NULL,
	data text default '',
	save_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
