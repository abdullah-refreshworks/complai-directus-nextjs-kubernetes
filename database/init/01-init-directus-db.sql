-- Initialize Directus database
-- This script sets up the initial database structure for Directus

-- Create the directus database if it doesn't exist
-- (This is handled by the POSTGRES_DB environment variable)

-- Create extensions that Directus might need
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a sample posts table for demonstration
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    slug VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'draft',
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a sample pages table for demonstration
CREATE TABLE IF NOT EXISTS pages (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    slug VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'draft',
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO posts (title, content, slug, status) VALUES 
('Welcome to Complai', 'This is your first post created by the database initialization script. You can manage this content through the Directus admin panel.', 'welcome-to-complai', 'published'),
('Getting Started with Directus', 'Directus is a powerful headless CMS that provides a beautiful admin interface and a robust API. Learn how to use it effectively.', 'getting-started-with-directus', 'published'),
('Deploying to Azure Kubernetes', 'This application is deployed on Azure Kubernetes Service, providing scalability and reliability for your content management needs.', 'deploying-to-azure-kubernetes', 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO pages (title, content, slug, status) VALUES 
('About Us', 'This is the about page for Complai. You can edit this content through the Directus admin panel.', 'about', 'published'),
('Contact', 'Get in touch with us through this contact page. All content is managed through Directus CMS.', 'contact', 'published')
ON CONFLICT (slug) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_slug ON posts(slug);
CREATE INDEX IF NOT EXISTS idx_pages_status ON pages(status);
CREATE INDEX IF NOT EXISTS idx_pages_slug ON pages(slug);
