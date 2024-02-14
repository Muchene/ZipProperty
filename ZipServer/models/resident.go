package models

type Resident struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Email  string `json:"email"`
	DOB    string `json:"dob"`
	IDType string `json:"idType"`
}
