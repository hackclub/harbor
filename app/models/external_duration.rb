class ExternalDuration < ApplicationRecord
  belongs_to :ysws_provider
  belongs_to :user

  enum type: { # the type of the entity
    file: 0,
    app: 1,
    domain: 2
  }

  enum category: { # These come from https://wakatime.com/developers#external_durations
    coding: 0,
    building: 1,
    indexing: 2,
    debugging: 3,
    browsing: 4,
    running_tests: 5,
    writing_tests: 6,
    manual_testing: 7,
    writing_docs: 8,
    communicating: 9,
    code_reviewing: 10,
    researching: 11,
    learning: 12,
    designing: 13
  }
end
