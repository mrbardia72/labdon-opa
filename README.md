# Go + OPA + Rego Authorization Example

A simple example of using **Go**, **Open Policy Agent (OPA)**, and **Rego** to implement API authorization.

The main idea is to keep authorization rules outside of the Go application:

* **Go** handles HTTP requests and application logic.
* **OPA** evaluates authorization policies.
* **Rego** defines the authorization rules.

> **Key idea:** Go handles the application logic, while Rego defines the authorization rules.

---

## Table of Contents

* [Project Structure](#project-structure)
* [How It Works](#how-it-works)
* [Authorization Policy](#authorization-policy)

  * [Admin](#admin)
  * [User](#user)
  * [Manager](#manager)
* [Input Sent to OPA](#input-sent-to-opa)
* [Installation](#installation)
* [Run the Application](#run-the-application)
* [API Examples](#api-examples)

  * [GET /users](#get-users)
  * [POST /users](#post-users)
  * [DELETE /users](#delete-users)
  * [GET /reports](#get-reports)
* [Testing Manager Permissions](#testing-manager-permissions)
* [Testing Admin Permissions](#testing-admin-permissions)
* [Understanding Rego Rules](#understanding-rego-rules)
* [Authorization vs Authentication](#authorization-vs-authentication)
* [Current Limitations](#current-limitations)
* [Responsibilities](#go-opa--rego-responsibilities)
* [Overall Architecture](#overall-architecture)

---

## Project Structure

```text
.
├── app.go
├── go.mod
├── go.sum
└── policy
    └── authorization.rego
```

---

## How It Works

The request flow is:

```text
HTTP Request
     |
     v
Go HTTP Handler
     |
     | user + method + path
     v
OPA
     |
     v
authorization.rego
     |
     v
allow = true / false
     |
     v
Go Handler
     |
     +---- true  -> 200 OK
     |
     +---- false -> 403 Forbidden
```

For every HTTP request, Go creates an authorization input containing information such as:

* User
* HTTP method
* Request path

OPA evaluates this input against the Rego policy and returns whether the request is allowed.

---

# Authorization Policy

The authorization policy is located at:

```text
policy/authorization.rego
```

The current policy defines three roles:

| Role      | Permissions                                                  |
| --------- | ------------------------------------------------------------ |
| `admin`   | All endpoints and HTTP methods handled by the application    |
| `manager` | `GET /users`, `POST /users`, `DELETE /users`, `GET /reports` |
| `user`    | `GET /users`                                                 |

### Permission Matrix

| Role      | GET `/users` | POST `/users` | DELETE `/users` | GET `/reports` |
| --------- | :----------: | :-----------: | :-------------: | :------------: |
| `admin`   |       ✅      |       ✅       |        ✅        |        ✅       |
| `manager` |       ✅      |       ✅       |        ✅        |        ✅       |
| `user`    |       ✅      |       ❌       |        ❌        |        ❌       |

---

## Admin

Admins can access everything.

```rego
allow {
    input.user.role == "admin"
}
```

---

## User

Normal users can only perform:

```text
GET /users
```

Policy:

```rego
allow {
    input.user.role == "user"
    input.method == "GET"
    input.path == "/users"
}
```

---

## Manager

Managers can perform:

```text
GET    /users
POST   /users
DELETE /users
GET    /reports
```

---

# Input Sent to OPA

For every HTTP request, Go creates an authorization input.

For example:

```json
{
  "user": {
    "name": "Bardia",
    "role": "user"
  },
  "method": "GET",
  "path": "/users"
}
```

The Rego policy accesses this data through the `input` variable:

```rego
input.user.role
input.method
input.path
```

---

# Installation

Initialize the Go module:

```bash
go mod init example
```

Install OPA:

```bash
go get github.com/open-policy-agent/opa
```

> **[PLACEHOLDER]** If the project already contains a finalized `go.mod`, document the exact dependency/version setup here instead of running the initialization commands above.

---

# Run the Application

Start the application:

```bash
go run app.go
```

You should see:

```text
server listening on :8080
```

The API is available at:

```text
http://localhost:8080
```

---

# API Examples

The examples below use the currently hard-coded user:

```text
Bardia
role = user
```

---

## GET `/users`

Request:

```bash
curl http://localhost:8080/users
```

The input sent to OPA is:

```json
{
  "user": {
    "name": "Bardia",
    "role": "user"
  },
  "method": "GET",
  "path": "/users"
}
```

The following policy matches:

```rego
allow {
    input.user.role == "user"
    input.method == "GET"
    input.path == "/users"
}
```

Therefore:

```text
allow = true
```

Response:

```http
HTTP/1.1 200 OK
```

Example response:

```json
[
  {
    "name": "Bardia",
    "role": "user"
  },
  {
    "name": "Sara",
    "role": "admin"
  }
]
```

---

## POST `/users`

Request:

```bash
curl -X POST http://localhost:8080/users
```

The current user has:

```text
role = user
```

Normal users can only perform:

```text
GET /users
```

Therefore:

```text
allow = false
```

Response:

```http
HTTP/1.1 403 Forbidden
```

---

## DELETE `/users`

Request:

```bash
curl -X DELETE http://localhost:8080/users
```

The current user is a normal user.

The policy does not allow:

```text
user + DELETE /users
```

Therefore:

```text
allow = false
```

Response:

```http
HTTP/1.1 403 Forbidden
```

---

## GET `/reports`

Request:

```bash
curl http://localhost:8080/reports
```

The current user has:

```text
role = user
```

Only managers and admins can access reports.

Therefore:

```text
allow = false
```

Response:

```http
HTTP/1.1 403 Forbidden
```

---

# Testing Manager Permissions

To test the manager rules, change the user in `app.go`:

```go
user := User{
    Name: "Bardia",
    Role: "manager",
}
```

With the manager role, the following requests are allowed.

### GET `/users`

```bash
curl http://localhost:8080/users
```

### POST `/users`

```bash
curl -X POST http://localhost:8080/users
```

### DELETE `/users`

```bash
curl -X DELETE http://localhost:8080/users
```

### GET `/reports`

```bash
curl http://localhost:8080/reports
```

---

# Testing Admin Permissions

Change the user to:

```go
user := User{
    Name: "Bardia",
    Role: "admin",
}
```

The policy contains:

```rego
allow {
    input.user.role == "admin"
}
```

Therefore, an admin can access all endpoints and HTTP methods handled by the application.

For example:

```bash
curl http://localhost:8080/users
```

```bash
curl -X POST http://localhost:8080/users
```

```bash
curl -X DELETE http://localhost:8080/users
```

```bash
curl http://localhost:8080/reports
```

---

# Understanding Rego Rules

Multiple rules with the same name are alternative ways to make the rule true.

For example:

```rego
allow {
    input.user.role == "admin"
}

allow {
    input.user.role == "user"
    input.method == "GET"
}
```

This can be understood as:

```text
admin
   OR
user + GET
```

If any rule matches:

```text
allow = true
```

If none of the rules match:

```text
allow = false
```

because the policy defines:

```rego
default allow = false
```

---

# Authorization vs Authentication

This example demonstrates **authorization**, not authentication.

## Authentication

Authentication answers:

> Who is this user?

For example:

```text
JWT
 |
 v
Verify JWT
 |
 v
Identify User
```

## Authorization

Authorization answers:

> Is this user allowed to perform this action?

For example:

```text
Bardia
role = user
 |
 v
GET /users
 |
 v
OPA
 |
 v
allow = true
```

A real application would typically have a flow like:

```text
HTTP Request
     |
     v
Authorization Header
     |
     v
JWT
     |
     v
Authentication
     |
     v
User Identity + Roles
     |
     v
OPA / Rego
     |
     v
Allow / Deny
     |
     +---- Allow -> Handler
     |
     +---- Deny  -> 403
```

---

# Current Limitations

This is a learning example.

The user is currently hard-coded in Go:

```go
user := User{
    Name: "Bardia",
    Role: "user",
}
```

In a real application, the user information would normally come from a verified JWT or another authentication mechanism.

The next step would be to replace the hard-coded user with claims extracted from a verified JWT.

---

# Go + OPA + Rego Responsibilities

| Component | Responsibility             |
| --------- | -------------------------- |
| **Go**    | HTTP and application logic |
| **OPA**   | Policy evaluation          |
| **Rego**  | Authorization rules        |

---

# Overall Architecture

```text
                 HTTP Request
                      |
                      v
                    Go API
                      |
                      | input
                      v
                     OPA
                      |
                      v
              authorization.rego
                      |
                      v
                allow = true?
                 /          \
               YES           NO
                |             |
                v             v
             Handler        403
                |
                v
             200 OK
```

The key idea is:

> **Go handles the application logic, while Rego defines the authorization rules.**
