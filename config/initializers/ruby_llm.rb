RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.default_model = "gpt-4.1"
  # config.gemini_api_key = ENV['GEMINI_API_KEY']
end
