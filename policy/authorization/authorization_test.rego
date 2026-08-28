package authorization_test

import data.authorization

test_admin_can_access_everything if {
	authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "admin",
		},
		"method": "DELETE",
		"path": "/users",
	}
}

test_user_can_get_users if {
	authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "user",
		},
		"method": "GET",
		"path": "/users",
	}
}

test_user_cannot_post_users if {
	not authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "user",
		},
		"method": "POST",
		"path": "/users",
	}
}

test_user_cannot_delete_users if {
	not authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "user",
		},
		"method": "DELETE",
		"path": "/users",
	}
}

test_manager_can_get_users if {
	authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "manager",
		},
		"method": "GET",
		"path": "/users",
	}
}

test_manager_can_post_users if {
	authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "manager",
		},
		"method": "POST",
		"path": "/users",
	}
}

test_manager_can_delete_users if {
	authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "manager",
		},
		"method": "DELETE",
		"path": "/users",
	}
}

test_manager_can_get_reports if {
	authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "manager",
		},
		"method": "GET",
		"path": "/reports",
	}
}

test_manager_cannot_post_reports if {
	not authorization.allow with input as {
		"user": {
			"name": "Bardia",
			"role": "manager",
		},
		"method": "POST",
		"path": "/reports",
	}
}
