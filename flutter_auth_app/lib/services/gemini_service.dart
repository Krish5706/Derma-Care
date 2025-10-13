import 'package:google_generative_ai/google_generative_ai.dart';

/// Simple wrapper around Gemini Flash for disease info retrieval.
class GeminiService {
  final String apiKey; // Provide via constructor

  GeminiService(this.apiKey);

  /// Fetch structured info about a skin disease using Gemini Flash.
  /// Returns a formatted markdown string suitable for rendering in a Text/SelectableText widget.
  Future<String> getDiseaseInfo(String diseaseName) async {
    if (apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY');
    }

    final model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1000,
      ),
    );

    final prompt =
        'First, verify if "$diseaseName" is a recognized skin condition. If it is not, your entire response should be exactly "This does not appear to be a recognized skin condition." If it is a valid skin condition, provide a detailed and comprehensive overview of it. Include sections for Symptoms, Causes, Treatment Options, and Skin Care recommendations. Be thorough in each section. Format the output in markdown.';
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? 'Could not get information.';
  }
}
