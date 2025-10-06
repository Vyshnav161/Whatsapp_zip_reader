import 'package:flutter_test/flutter_test.dart';
import 'package:WZipChat/utils/link_detector.dart';

void main() {
  group('LinkDetector', () {
    group('detectLinks', () {
      test('should detect web URLs with https protocol', () {
        const text = 'Check out https://example.com for more info';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com');
        expect(links[0].type, LinkType.webUrl);
        expect(links[0].start, 10);
        expect(links[0].end, 29);
      });

      test('should detect web URLs with http protocol', () {
        const text = 'Visit http://example.com';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'http://example.com');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should detect web URLs starting with www', () {
        const text = 'Go to www.example.com';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'www.example.com');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should detect URLs with paths and parameters', () {
        const text = 'Check https://example.com/path?param=value#section';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com/path?param=value#section');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should NOT detect PDF files as links', () {
        const text = 'Download the PDF from document.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should NOT detect image files as links', () {
        const text = 'Images: photo.jpg, image.jpeg, pic.png, animation.gif, bitmap.bmp, modern.webp, vector.svg';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should NOT detect video files as links', () {
        const text = 'Videos: movie.mp4, clip.avi, video.mov, old.wmv, flash.flv, web.webm, hd.mkv, mobile.m4v';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should NOT detect audio files as links', () {
        const text = 'Audio files: song.mp3, voice.opus, music.wav, audio.flac, sound.aac, recording.ogg, track.m4a, file.wma';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should NOT detect document files as links', () {
        const text = 'Files: document.doc, file.docx, readme.txt, notes.rtf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should detect web URLs but ignore file extensions in same text', () {
        const text = 'Visit https://example.com and check document.pdf or photo.jpg';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should detect web URLs with file extensions in the URL path', () {
        const text = 'Download from https://example.com/files/document.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com/files/document.pdf');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should detect www URLs with file extensions in the URL path', () {
        const text = 'Get it from www.example.com/images/photo.jpg';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'www.example.com/images/photo.jpg');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should handle text with no links', () {
        const text = 'This is just regular text with no links';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should handle empty text', () {
        const text = '';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should handle text with only file names', () {
        const text = 'Check these files: document.pdf, photo.jpg, video.mp4, audio.opus';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 0);
      });

      test('should sort multiple web URLs by start position', () {
        const text = 'Visit www.second.com first then https://first.com';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 2);
        // Links should be sorted by their position in the text
        expect(links[0].text, 'www.second.com'); // appears first in text
        expect(links[1].text, 'https://first.com'); // appears second in text
      });

      test('should detect multiple web URLs in one message', () {
        const text = 'Visit https://example.com and also check www.google.com';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 2);
        expect(links[0].text, 'https://example.com');
        expect(links[0].type, LinkType.webUrl);
        expect(links[1].text, 'www.google.com');
        expect(links[1].type, LinkType.webUrl);
      });
    });

    group('classifyLink', () {
      test('should always classify as web URL', () {
        expect(LinkDetector.classifyLink('https://example.com'), LinkType.webUrl);
        expect(LinkDetector.classifyLink('www.example.com'), LinkType.webUrl);
        expect(LinkDetector.classifyLink('document.pdf'), LinkType.webUrl);
        expect(LinkDetector.classifyLink('photo.jpg'), LinkType.webUrl);
        expect(LinkDetector.classifyLink('anything'), LinkType.webUrl);
      });
    });

    group('formatUrlForLaunching', () {
      test('should add https protocol to URLs without protocol', () {
        expect(
          LinkDetector.formatUrlForLaunching('example.com', LinkType.webUrl),
          'https://example.com',
        );
        expect(
          LinkDetector.formatUrlForLaunching('www.example.com', LinkType.webUrl),
          'https://www.example.com',
        );
      });

      test('should not modify URLs that already have protocol', () {
        expect(
          LinkDetector.formatUrlForLaunching('https://example.com', LinkType.webUrl),
          'https://example.com',
        );
        expect(
          LinkDetector.formatUrlForLaunching('http://example.com', LinkType.webUrl),
          'http://example.com',
        );
      });

      test('should handle URLs with paths', () {
        expect(
          LinkDetector.formatUrlForLaunching('example.com/path', LinkType.webUrl),
          'https://example.com/path',
        );
        expect(
          LinkDetector.formatUrlForLaunching('www.example.com/path?param=value', LinkType.webUrl),
          'https://www.example.com/path?param=value',
        );
      });
    });

    group('isValidLink', () {
      test('should validate web URLs correctly', () {
        expect(LinkDetector.isValidLink('https://example.com', LinkType.webUrl), true);
        expect(LinkDetector.isValidLink('www.example.com', LinkType.webUrl), true);
        expect(LinkDetector.isValidLink('http://example.com/path', LinkType.webUrl), true);
      });

      test('should reject invalid URLs', () {
        expect(LinkDetector.isValidLink('not-a-url', LinkType.webUrl), false);
        expect(LinkDetector.isValidLink('just text', LinkType.webUrl), false);
        expect(LinkDetector.isValidLink('', LinkType.webUrl), false);
      });
    });

    group('file extension filtering', () {
      test('should not detect standalone file names as links', () {
        const testCases = [
          'document.pdf',
          'photo.jpg',
          'video.mp4',
          'audio.opus',
          'song.mp3',
          'voice.wav',
          'music.flac',
          'sound.aac',
          'recording.ogg',
          'track.m4a',
          'file.wma',
          'image.png',
          'pic.gif',
          'bitmap.bmp',
          'modern.webp',
          'vector.svg',
          'clip.avi',
          'movie.mov',
          'old.wmv',
          'flash.flv',
          'web.webm',
          'hd.mkv',
          'mobile.m4v',
          'notes.txt',
          'report.doc',
          'file.docx',
          'readme.rtf',
          'archive.zip',
          'backup.rar',
        ];

        for (final testCase in testCases) {
          final links = LinkDetector.detectLinks('Check this file: $testCase');
          expect(links.length, 0, reason: 'Should not detect $testCase as a link');
        }
      });

      test('should detect URLs even if they contain file extensions in path', () {
        const testCases = [
          'https://example.com/document.pdf',
          'http://site.org/photo.jpg',
          'www.example.com/video.mp4',
          'https://cdn.example.com/audio.opus',
        ];

        for (final testCase in testCases) {
          final links = LinkDetector.detectLinks('Download from $testCase');
          expect(links.length, 1, reason: 'Should detect $testCase as a web URL');
          expect(links[0].text, testCase);
          expect(links[0].type, LinkType.webUrl);
        }
      });
    });
  });
}