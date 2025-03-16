terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

data "google_project" "project" {
  project_id = "beratyesbek-test"
}

provider "google" {
  credentials = file("beratyesbek-test-188958b60b87.json")
  project = "beratyesbek-test"
  region  = "europe-west1"
}

resource "google_storage_bucket" "large-csv-file-bucket" {
  location = "europe-west1"
  name     = "large-csv-file-bucket"
  project  = "beratyesbek-test"

}

resource "google_workflows_workflow" "large-csv-file-workflow" {
  name            = "large-csv-file-workflow"
  region          = "europe-west1"
  service_account = "beratyesbek-test@beratyesbek-test.iam.gserviceaccount.com"
  source_contents = file("workflows/large-csv-file-workflow.yaml")
}

resource "google_project_iam_member" "gcs_service_account_pubsub_publisher" {
  project = "beratyesbek-test"
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_eventarc_trigger" "large-csv-file-trigger" {
  location = "europe-west1"
  name     = "large-csv-file-trigger"
  project  = "beratyesbek-test"
  service_account = "beratyesbek-test@beratyesbek-test.iam.gserviceaccount.com"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.large-csv-file-bucket.name
  }

  destination {
    workflow = google_workflows_workflow.large-csv-file-workflow.name
  }

  depends_on = [google_project_iam_member.gcs_service_account_pubsub_publisher]

}


resource "google_cloud_run_v2_job" "cr-large-csv-file-job" {
  location = "europe-west1"
  name     = "cr-large-csv-file-job"
  project  = "beratyesbek-test"

  template {
    template {
      service_account = "beratyesbek-test@beratyesbek-test.iam.gserviceaccount.com"
      containers {
        image = "europe-west1-docker.pkg.dev/beratyesbek-test/berat-repository/big-query-csv-loader:4"
      }
    }

  }
}

