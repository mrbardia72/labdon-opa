package authorization

# METADATA
# entrypoint: true
#
default allow := false

# -------------------------------------------------
# Admin just admin allow
# -------------------------------------------------

# Admin can GET reports.
allow if {
	input.user.role == "admin"
}

# -------------------------------------------------
# User
# -------------------------------------------------

# User can only GET /users.
allow if {
	input.user.role == "user"
	input.method == "GET"
	input.path == "/users"
}

# -------------------------------------------------
# Manager
# -------------------------------------------------

# Manager can GET users.
allow if {
	input.user.role == "manager"
	input.method == "GET"
	input.path == "/users"
}

# Manager can POST new users.
allow if {
	input.user.role == "manager"
	input.method == "POST"
	input.path == "/users"
}

# Manager can DELETE users.
allow if {
	input.user.role == "manager"
	input.method == "DELETE"
	input.path == "/users"
}

# -------------------------------------------------
# Report
# -------------------------------------------------

# Admin can GET reports.
# Manager can GET reports.
allow if {
	input.user.role == "manager"
	input.method == "GET"
	input.path == "/reports"
}
