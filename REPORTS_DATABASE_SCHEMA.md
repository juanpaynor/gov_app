# Reports Feature - Database Schema

## Overview
This document outlines the complete database schema for the Reports feature with admin-configurable categories.

---

## SQL Scripts to Execute

Copy and paste the following SQL scripts into your Supabase SQL Editor in order.

---

## 1. Create Tables

### Create report_categories table
```sql
-- Stores all report categories that can be managed by admins
CREATE TABLE report_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT DEFAULT '#3B82F6',
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_report_categories_active ON report_categories(is_active, display_order);
```

### Create reports table
```sql
-- Main table for storing user-submitted reports
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES report_categories(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  location_address TEXT,
  urgency TEXT CHECK (urgency IN ('low', 'medium', 'high')) DEFAULT 'medium',
  status TEXT CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')) DEFAULT 'pending',
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_reports_user_id ON reports(user_id);
CREATE INDEX idx_reports_category_id ON reports(category_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX idx_reports_assigned_to ON reports(assigned_to);
```

### Create report_attachments table
```sql
-- Stores photos and files attached to reports
CREATE TABLE report_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT,
  file_type TEXT,
  file_size INTEGER,
  uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_report_attachments_report_id ON report_attachments(report_id);
```

### Create report_comments table
```sql
-- Stores follow-up comments and updates on reports
CREATE TABLE report_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_report_comments_report_id ON report_comments(report_id, created_at);
```

### Create report_status_history table
```sql
-- Tracks all status changes for audit trail
CREATE TABLE report_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT NOT NULL,
  changed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_report_status_history_report_id ON report_status_history(report_id, created_at);
```

### Create category_custom_fields table (Optional)
```sql
-- Allows categories to have custom fields (e.g., tricycle number for fare reports)
CREATE TABLE category_custom_fields (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID NOT NULL REFERENCES report_categories(id) ON DELETE CASCADE,
  field_name TEXT NOT NULL,
  field_label TEXT NOT NULL,
  field_type TEXT CHECK (field_type IN ('text', 'number', 'dropdown', 'textarea')) DEFAULT 'text',
  is_required BOOLEAN DEFAULT false,
  options JSONB,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_category_custom_fields_category_id ON category_custom_fields(category_id, display_order);
```

### Create report_custom_data table (Optional)
```sql
-- Stores values for custom fields
CREATE TABLE report_custom_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  field_id UUID NOT NULL REFERENCES category_custom_fields(id) ON DELETE CASCADE,
  value TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_report_custom_data_report_id ON report_custom_data(report_id);
CREATE UNIQUE INDEX idx_report_custom_data_unique ON report_custom_data(report_id, field_id);
```

---

## 2. Enable Row Level Security (RLS)

### RLS Policies for report_categories
```sql
ALTER TABLE report_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active categories"
  ON report_categories FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage categories"
  ON report_categories FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
```

### RLS Policies for reports
```sql
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reports"
  ON reports FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own pending reports"
  ON reports FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending');

CREATE POLICY "Admins can view all reports"
  ON reports FOR SELECT
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

CREATE POLICY "Admins can update all reports"
  ON reports FOR UPDATE
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
```

### RLS Policies for report_attachments
```sql
ALTER TABLE report_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own report attachments"
  ON report_attachments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM reports
      WHERE reports.id = report_attachments.report_id
      AND reports.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can upload to own reports"
  ON report_attachments FOR INSERT
  WITH CHECK (
    auth.uid() = uploaded_by AND
    EXISTS (
      SELECT 1 FROM reports
      WHERE reports.id = report_attachments.report_id
      AND reports.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all attachments"
  ON report_attachments FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
```

### RLS Policies for report_comments
```sql
ALTER TABLE report_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view comments on own reports"
  ON report_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM reports
      WHERE reports.id = report_comments.report_id
      AND reports.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can comment on own reports"
  ON report_comments FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM reports
      WHERE reports.id = report_comments.report_id
      AND reports.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all comments"
  ON report_comments FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
```

### RLS Policies for report_status_history
```sql
ALTER TABLE report_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own report history"
  ON report_status_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM reports
      WHERE reports.id = report_status_history.report_id
      AND reports.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all history"
  ON report_status_history FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
```

---

## 3. Create Database Functions and Triggers

### Function to auto-update updated_at timestamp
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Apply updated_at triggers
```sql
CREATE TRIGGER update_report_categories_updated_at
  BEFORE UPDATE ON report_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at
  BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_comments_updated_at
  BEFORE UPDATE ON report_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Function to track status changes
```sql
CREATE OR REPLACE FUNCTION log_report_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO report_status_history (report_id, old_status, new_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid());
    
    IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
      NEW.resolved_at = NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Apply status tracking trigger
```sql
CREATE TRIGGER track_report_status_changes
  BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION log_report_status_change();
```

---

## 4. Create Storage Bucket

### Create report-attachments bucket
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('report-attachments', 'report-attachments', true);
```

### Storage bucket policies
```sql
CREATE POLICY "Users can upload attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'report-attachments' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Anyone can view attachments"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'report-attachments');

CREATE POLICY "Users can delete own attachments"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'report-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Admins can manage all attachments"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'report-attachments' AND
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );
```

---

## 5. Insert Initial Data

### Insert default categories
```sql
INSERT INTO report_categories (name, description, icon, color, display_order)
VALUES
  ('Public Works Issues', 'Roads, bridges, streetlights, drainage, and infrastructure', '🏗️', '#3B82F6', 1),
  ('Tricycle Fare Complaint', 'Overcharging, refused passengers, route violations, driver misconduct', '🛺', '#F59E0B', 2),
  ('Public Safety Concerns', 'Crime, accidents, suspicious activity', '🚨', '#EF4444', 3),
  ('Environmental Issues', 'Garbage, pollution, flooding, illegal dumping', '🌿', '#10B981', 4),
  ('Health Concerns', 'Sanitation, disease outbreaks, health hazards', '🏥', '#8B5CF6', 5),
  ('Other Municipal Services', 'General complaints and service requests', '📋', '#6B7280', 6);
```

### Insert custom fields for Tricycle reports (Optional)
```sql
DO $$
DECLARE
  tricycle_category_id UUID;
BEGIN
  SELECT id INTO tricycle_category_id
  FROM report_categories
  WHERE name = 'Tricycle Fare Complaint'
  LIMIT 1;

  INSERT INTO category_custom_fields (category_id, field_name, field_label, field_type, is_required, display_order)
  VALUES
    (tricycle_category_id, 'tricycle_number', 'Tricycle Plate Number', 'text', false, 1),
    (tricycle_category_id, 'driver_name', 'Driver Name (if known)', 'text', false, 2),
    (tricycle_category_id, 'route_taken', 'Route Taken', 'text', false, 3),
    (tricycle_category_id, 'fare_charged', 'Fare Charged', 'number', false, 4),
    (tricycle_category_id, 'official_fare', 'Official Fare', 'number', false, 5);
END $$;
```

---

## 6. Set Admin User (Important!)

To give admin access to a user, run this SQL:

```sql
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'
WHERE email = 'your-admin-email@example.com';
```

Replace `your-admin-email@example.com` with the actual admin email address.

---

## Execution Order Summary

Execute the SQL scripts in this order:
1. Create all tables (section 1)
2. Enable RLS and create policies (section 2)
3. Create functions and triggers (section 3)
4. Create storage bucket and policies (section 4)
5. Insert initial data (section 5)
6. Set admin user (section 6)

---

## Field Descriptions

### report_categories
- `id` - Unique identifier
- `name` - Category name
- `description` - Optional explanation
- `icon` - Icon or emoji
- `color` - Hex color code
- `is_active` - Show/hide category
- `display_order` - Sort order
- `created_at`, `updated_at` - Timestamps

### reports
- `id` - Unique identifier
- `user_id` - User who created report
- `category_id` - Report category
- `title` - Short subject
- `description` - Detailed description
- `location_lat`, `location_lng` - GPS coordinates
- `location_address` - Human-readable address
- `urgency` - low, medium, high
- `status` - pending, in_progress, resolved, rejected
- `assigned_to` - Admin assigned
- `admin_notes` - Internal notes
- `created_at`, `updated_at`, `resolved_at` - Timestamps

### report_attachments
- `id` - Unique identifier
- `report_id` - Parent report
- `file_url` - Storage URL
- `file_name` - Original filename
- `file_type` - MIME type
- `file_size` - Size in bytes
- `uploaded_by` - Uploader ID
- `created_at` - Timestamp

### report_comments
- `id` - Unique identifier
- `report_id` - Parent report
- `user_id` - Comment author
- `comment` - Comment text
- `is_admin` - Admin flag
- `created_at`, `updated_at` - Timestamps

### report_status_history
- `id` - Unique identifier
- `report_id` - Parent report
- `old_status`, `new_status` - Status values
- `changed_by` - Admin who changed
- `notes` - Optional notes
- `created_at` - Timestamp

---

## Notes
- Admin role uses `(auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'`
- Foreign keys use CASCADE or RESTRICT appropriately
- Indexes optimize common queries
- Custom fields system is optional
- All SQL is PostgreSQL compatible for Supabase
