# Example Spec - Task Manager App

This is an example specification file. Copy this as `spec.md` and customize for your project.

## Overview

A simple task management web application that allows users to create, organize, and track tasks.

## Tech Stack

- **Frontend**: React + TypeScript
- **Backend**: Cloudflare Workers (Hono)
- **Database**: Cloudflare D1 (SQLite)
- **Hosting**: Cloudflare Pages

## Features

### User Authentication

Users can sign up and log in to manage their tasks.

**Requirements:**
- Email/password signup
- Email verification
- Password reset flow
- Session management with secure cookies

### Task Management

Core functionality for creating and managing tasks.

**Requirements:**
- Create tasks with title, description, due date
- Edit and delete tasks
- Mark tasks as complete/incomplete
- Assign priority (high, medium, low)
- Add tags/labels to tasks

### Task Organization

Users can organize tasks into projects and lists.

**Requirements:**
- Create projects to group related tasks
- Drag-and-drop reordering
- Filter tasks by status, priority, tags
- Search tasks by title/description

### Dashboard

Overview of tasks and productivity metrics.

**Requirements:**
- Today's tasks view
- Upcoming tasks (next 7 days)
- Overdue tasks highlight
- Completion statistics

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/signup | Create account |
| POST | /api/auth/login | Login |
| POST | /api/auth/logout | Logout |
| GET | /api/tasks | List tasks |
| POST | /api/tasks | Create task |
| PUT | /api/tasks/:id | Update task |
| DELETE | /api/tasks/:id | Delete task |
| GET | /api/projects | List projects |
| POST | /api/projects | Create project |

## Database Schema

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  project_id TEXT,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATETIME,
  priority TEXT DEFAULT 'medium',
  completed BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  color TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## Non-Functional Requirements

- Page load under 2 seconds
- Mobile-responsive design
- Accessibility (WCAG 2.1 AA)
- Rate limiting on API endpoints

## Out of Scope (v1)

- Team collaboration / shared tasks
- Recurring tasks
- File attachments
- Mobile app
- Notifications / reminders
