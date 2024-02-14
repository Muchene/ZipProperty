package app

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
)

type ZipApp struct {
	log    *log.Logger
	cfg    *Config
	router *mux.Router
}

type Config struct {
	Port   uint16 `json:"port"`
	Host   string `json:"host"`
	DbHost string `json:"db_host"`
	DbName string `json:"db_name"`
	DbPort uint16 `json:"db_port"`
}

func NewZipApp(log *log.Logger, cfg *Config) *ZipApp {
	router := mux.NewRouter()

	app := &ZipApp{
		log:    log,
		cfg:    cfg,
		router: router,
	}

	router.HandleFunc("/health", app.healthHandler).Methods("GET")
	router.HandleFunc("/residents", app.residentsHandler).Methods("GET")
	router.HandleFunc("/residents/{id}", app.residentHandler).Methods("GET")
	router.HandleFunc("/residents", app.createResidentHandler).Methods("POST")
	router.HandleFunc("/residents/{id}", app.updateResidentHandler).Methods("PUT")
	router.HandleFunc("/residents/{id}", app.patchResidentHandler).Methods("PATCH")
	router.HandleFunc("/residents/{id}", app.deleteResidentHandler).Methods("DELETE")

	return app
}

func (app *ZipApp) Run() error {
	app.log.Infof("Starting ZipServer on %s:%d", app.cfg.Host, app.cfg.Port)
	return http.ListenAndServe(fmt.Sprintf("%s:%d", app.cfg.Host, app.cfg.Port), app.router)
}

func (app *ZipApp) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func ConfigFromFile(path string) (*Config, error) {
	configBytes, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var config Config
	err = json.Unmarshal(configBytes, &config)
	if err != nil {
		return nil, err
	}
	return &config, nil
}
