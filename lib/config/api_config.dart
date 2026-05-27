/// API Configuration for the Weight Scale App
/// 
/// This file contains configuration for external APIs.
/// For security, never commit real API keys to version control.
library;

class APIConfig {
  /// Google Gemini API Key
  /// 
  /// To get your API key:
  /// 1. Go to https://aistudio.google.com/apikey
  /// 2. Sign in with your Google account
  /// 3. Create a new API key
  /// 4. Copy the key and replace the placeholder below
  /// 
  /// IMPORTANT: Keep your API key secure!
  /// - Do not share it publicly
  /// - Do not commit it to version control
  /// - Consider using environment variables in production
  static const String geminiApiKey = 'AIzaSyABKLrFRiAtyyglugUh41L54A1cjSoVF-A';
  static const String geminiModel = 'gemini-2.5-flash-lite';
  /// Alternative: Load API key from environment variables
  /// This is more secure for production apps
  static String? get geminiApiKeyFromEnv => 
      const String.fromEnvironment('AIzaSyABKLrFRiAtyyglugUh41L54A1cjSoVF-A');
  
  /// Check if API key is configured
  static bool get isGeminiConfigured => 
      geminiApiKey != 'AIzaSyABKLrFRiAtyyglugUh41L54A1cjSoVF-A' &&
      geminiApiKey.isNotEmpty;
  
  /// Get the effective API key (from config or environment)
  static String? get effectiveGeminiKey =>
      geminiApiKey.isNotEmpty ? geminiApiKey : null;

  /// API endpoints
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  /// Model configuration

  /// Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration imageUploadTimeout = Duration(seconds: 60);


}