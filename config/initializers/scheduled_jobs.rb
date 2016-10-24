Sidekiq::Cron::Job.destroy_all!
if Rails.env.staging? || Rails.env.development?
  Sidekiq::Cron::Job.create(name: "I-Educar Synchronization - every 5 min", cron: "*/5 * * * *", class: "IeducarSynchronizerWorker")
elsif Rails.env.production?
  Sidekiq::Cron::Job.create(name: "I-Educar Synchronization - every 20 min", cron: "*/20 * * * *", class: "IeducarSynchronizerWorker")
end
