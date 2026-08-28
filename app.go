package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/open-policy-agent/opa/ast"
	"github.com/open-policy-agent/opa/rego"
)

// User represents a user in the system.
type User struct {
	Name string `json:"name"`
	Role string `json:"role"`
}

// AuthzInput holds the input for authorization.
type AuthzInput struct {
	User   User   `json:"user"`
	Method string `json:"method"`
	Path   string `json:"path"`
}

// PreparedEvalQuery holds the prepared Rego state that has been pre-processed for subsequent evaluations.
var (
	query rego.PreparedEvalQuery
)

func main() {
	module, err := os.ReadFile("policy/authorization/authorization.rego")
	if err != nil {
		log.Fatal(err)
	}

	query, err = rego.
		New(
			rego.SetRegoVersion(ast.RegoV1),
			rego.Module("authorization.rego", string(module)),
			rego.Query("data.authorization.allow"),
		).
		PrepareForEval(context.Background())

	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/users", usersHandler)
	http.HandleFunc("/reports", reportsHandler)

	log.Println("server listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// usersHandler handles the /users endpoint, returning a list of users.
func usersHandler(w http.ResponseWriter, r *http.Request) {
	user := User{
		Name: "Bardia",
		Role: "user",
	}

	input := AuthzInput{
		User:   user,
		Method: r.Method,
		Path:   r.URL.Path,
	}

	allowed, err := checkAuthorization(r.Context(), input)
	if err != nil {
		http.Error(w, "authorization error", http.StatusInternalServerError)
		return
	}

	if !allowed {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	users := []User{
		{Name: "Bardia", Role: "manager"},
		{Name: "Sara", Role: "admin"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// reportsHandler handles the /reports endpoint, returning a list of reports.
func reportsHandler(w http.ResponseWriter, r *http.Request) {
	user := User{
		Name: "Bardia",
		Role: "manager",
	}

	input := AuthzInput{
		User:   user,
		Method: r.Method,
		Path:   r.URL.Path,
	}

	allowed, err := checkAuthorization(r.Context(), input)
	if err != nil {
		http.Error(w, "authorization error", http.StatusInternalServerError)
		return
	}

	if !allowed {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	response := map[string]any{
		"message": "reports data",
		"reports": []string{
			"Report 1",
			"Report 2",
			"Report 3",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// checkAuthorization checks the authorization of a user against the policy.
func checkAuthorization(ctx context.Context, input AuthzInput) (bool, error) {
	results, err := query.Eval(
		ctx,
		rego.EvalInput(input),
	)
	if err != nil {
		return false, err
	}

	if len(results) == 0 {
		return false, nil
	}

	allowed, ok := results[0].Expressions[0].Value.(bool)
	if !ok {
		return false, fmt.Errorf("policy returned non-bool result")
	}

	return allowed, nil
}
