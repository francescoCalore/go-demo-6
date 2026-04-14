package main

import (
	"net/http"
	"testing"
	"time"
)

func TestRecordMetrics_DoesNotPanic(t *testing.T) {
	req, err := http.NewRequest("GET", "/demo/hello", nil)
	if err != nil {
		t.Fatalf("failed to create request: %v", err)
	}

	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("recordMetrics panicked: %v", r)
		}
	}()

	recordMetrics(time.Now(), req, http.StatusOK)
}
