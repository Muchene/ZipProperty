package app

import (
	"encoding/json"
	"net/http"
	"zipserver/models"
)

// ResidentsHandler returns a list of residents
func (app *ZipApp) residentsHandler(w http.ResponseWriter, r *http.Request) {
	residents := []models.Resident{
		{
			ID:     "1",
			Name:   "John Doe",
			Email:  "johndoe@example.com",
			DOB:    "1980-01-01",
			IDType: "drivers_license",
		},
		{
			ID:     "2",
			Name:   "Jane Doe",
			Email:  "janedoe@example.com",
			DOB:    "1985-02-02",
			IDType: "passport",
		},
	}

	json.NewEncoder(w).Encode(residents)
}

// ResidentHandler returns a single resident
func (app *ZipApp) residentHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotImplemented)
}

// CreateResidentHandler creates a new resident
func (app *ZipApp) createResidentHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotImplemented)
}

// UpdateResidentHandler updates an existing resident
func (app *ZipApp) updateResidentHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotImplemented)
}

// PatchResidentHandler updates an existing resident
func (app *ZipApp) patchResidentHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotImplemented)
}

// DeleteResidentHandler deletes an existing resident
func (app *ZipApp) deleteResidentHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotImplemented)
}
