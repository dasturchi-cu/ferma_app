# Database Schema

This document describes the expected Supabase database schema for the Ferma App.

## Required Tables

### 1. `farms` table
```sql
CREATE TABLE farms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID REFERENCES auth.users(id),
  chicken JSONB,
  egg JSONB,
  customers JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. `egg_productions` table (Optional - for granular realtime)
```sql
CREATE TABLE egg_productions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID REFERENCES farms(id),
  record_type TEXT NOT NULL CHECK (record_type IN ('production', 'sale', 'broken', 'large')),
  tray_count INTEGER NOT NULL,
  price_per_tray DECIMAL(10,2),
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. `customers` table (Optional - for granular realtime)
```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID REFERENCES farms(id),
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  total_debt DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Current Implementation

The app currently works with:
- **Primary data storage**: All data is stored in the `farms` table as JSONB columns
- **Realtime streams**: Optional granular streams for `egg_productions` and `customers` tables
- **Fallback**: If granular tables don't exist, the app falls back to the main `farms` table stream

## Error Handling

The app gracefully handles missing tables by:
1. Catching database errors
2. Logging warnings instead of crashing
3. Continuing with local data storage
4. Falling back to main farm table for all operations

## Setup Instructions

1. Create the `farms` table (required)
2. Optionally create `egg_productions` and `customers` tables for granular realtime
3. Set up Row Level Security (RLS) policies
4. Enable realtime for the tables you want to use

## Notes

- The app works without the granular tables - they're just for enhanced realtime features
- All core functionality uses the main `farms` table
- Local storage (Hive) provides offline functionality
