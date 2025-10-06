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

      test('should detect domain-only URLs', () {
        const text = 'Visit example.com for details';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'example.com');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should detect URLs with paths and parameters', () {
        const text = 'Check https://example.com/path?param=value#section';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com/path?param=value#section');
        expect(links[0].type, LinkType.webUrl);
      });

      test('should detect PDF files with https URL', () {
        const text = 'Download the PDF from https://example.com/document.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com/document.pdf');
        expect(links[0].type, LinkType.pdfFile);
      });

      test('should detect PDF files with local path', () {
        const text = 'Open /path/to/document.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, '/path/to/document.pdf');
        expect(links[0].type, LinkType.pdfFile);
      });

      test('should detect PDF files with Windows path', () {
        const text = 'Check C:\\Documents\\file.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'C:\\Documents\\file.pdf');
        expect(links[0].type, LinkType.pdfFile);
      });

      test('should detect PDF files with home directory path', () {
        const text = 'Open ~/Documents/file.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, '~/Documents/file.pdf');
        expect(links[0].type, LinkType.pdfFile);
      });

      test('should detect image files with various extensions', () {
        const text = 'Images: photo.jpg, image.jpeg, pic.png, animation.gif, bitmap.bmp, modern.webp, vector.svg';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 7);
        expect(links[0].text, 'photo.jpg');
        expect(links[0].type, LinkType.imageFile);
        expect(links[1].text, 'image.jpeg');
        expect(links[1].type, LinkType.imageFile);
        expect(links[2].text, 'pic.png');
        expect(links[2].type, LinkType.imageFile);
        expect(links[3].text, 'animation.gif');
        expect(links[3].type, LinkType.imageFile);
        expect(links[4].text, 'bitmap.bmp');
        expect(links[4].type, LinkType.imageFile);
        expect(links[5].text, 'modern.webp');
        expect(links[5].type, LinkType.imageFile);
        expect(links[6].text, 'vector.svg');
        expect(links[6].type, LinkType.imageFile);
      });

      test('should detect video files with various extensions', () {
        const text = 'Videos: movie.mp4, clip.avi, video.mov, old.wmv, flash.flv, web.webm, hd.mkv, mobile.m4v';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 8);
        expect(links[0].text, 'movie.mp4');
        expect(links[0].type, LinkType.videoFile);
        expect(links[1].text, 'clip.avi');
        expect(links[1].type, LinkType.videoFile);
        expect(links[2].text, 'video.mov');
        expect(links[2].type, LinkType.videoFile);
        expect(links[3].text, 'old.wmv');
        expect(links[3].type, LinkType.videoFile);
        expect(links[4].text, 'flash.flv');
        expect(links[4].type, LinkType.videoFile);
        expect(links[5].text, 'web.webm');
        expect(links[5].type, LinkType.videoFile);
        expect(links[6].text, 'hd.mkv');
        expect(links[6].type, LinkType.videoFile);
        expect(links[7].text, 'mobile.m4v');
        expect(links[7].type, LinkType.videoFile);
      });

      test('should detect image files with URLs', () {
        const text = 'Check out https://example.com/photo.jpg and www.site.com/image.png';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 2);
        expect(links[0].text, 'https://example.com/photo.jpg');
        expect(links[0].type, LinkType.imageFile);
        expect(links[1].text, 'www.site.com/image.png');
        expect(links[1].type, LinkType.imageFile);
      });

      test('should detect video files with URLs', () {
        const text = 'Watch https://example.com/video.mp4 or download ~/Movies/clip.avi';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 2);
        expect(links[0].text, 'https://example.com/video.mp4');
        expect(links[0].type, LinkType.videoFile);
        expect(links[1].text, '~/Movies/clip.avi');
        expect(links[1].type, LinkType.videoFile);
      });

      test('should detect document files with various extensions', () {
        const text = 'Files: document.doc, file.docx, readme.txt, notes.rtf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 4);
        expect(links[0].text, 'document.doc');
        expect(links[0].type, LinkType.documentFile);
        expect(links[1].text, 'file.docx');
        expect(links[1].type, LinkType.documentFile);
        expect(links[2].text, 'readme.txt');
        expect(links[2].type, LinkType.documentFile);
        expect(links[3].text, 'notes.rtf');
        expect(links[3].type, LinkType.documentFile);
      });

      test('should detect multiple different link types in one message', () {
        const text = 'Visit https://example.com and download document.pdf or check notes.txt';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 3);
        expect(links[0].text, 'https://example.com');
        expect(links[0].type, LinkType.webUrl);
        expect(links[1].text, 'document.pdf');
        expect(links[1].type, LinkType.pdfFile);
        expect(links[2].text, 'notes.txt');
        expect(links[2].type, LinkType.documentFile);
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

      test('should prioritize PDF detection over web URL for PDF links', () {
        const text = 'Download https://example.com/file.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 1);
        expect(links[0].text, 'https://example.com/file.pdf');
        expect(links[0].type, LinkType.pdfFile);
      });

      test('should sort links by start position', () {
        const text = 'Second example.com first https://first.com third document.pdf';
        final links = LinkDetector.detectLinks(text);
        
        expect(links.length, 3);
        // Links should be sorted by their position in the text
        expect(links[0].text, 'example.com'); // appears first in text
        expect(links[1].text, 'https://first.com'); // appears second in text
        expect(links[2].text, 'document.pdf'); // appears third in text
      });
    });

    group('classifyLink', () {
      test('should classify PDF links correctly', () {
        expect(LinkDetector.classifyLink('document.pdf'), LinkType.pdfFile);
        expect(LinkDetector.classifyLink('https://example.com/file.pdf'), LinkType.pdfFile);
        expect(LinkDetector.classifyLink('/path/to/file.pdf'), LinkType.pdfFile);
      });

      test('should classify document links correctly', () {
        expect(LinkDetector.classifyLink('document.doc'), LinkType.documentFile);
        expect(LinkDetector.classifyLink('file.docx'), LinkType.documentFile);
        expect(LinkDetector.classifyLink('readme.txt'), LinkType.documentFile);
        expect(LinkDetector.classifyLink('notes.rtf'), LinkType.documentFile);
      });

      test('should classify web URLs correctly', () {
        expect(LinkDetector.classifyLink('https://example.com'), LinkType.webUrl);
        expect(LinkDetector.classifyLink('www.example.com'), LinkType.webUrl);
        expect(LinkDetector.classifyLink('example.com'), LinkType.webUrl);
      });
    });

    group('formatUrlForLaunching', () {
      test('should add https protocol to web URLs without protocol', () {
        expect(
          LinkDetector.formatUrlForLaunching('example.com', LinkType.webUrl),
          'https://example.com',
        );
        expect(
          LinkDetector.formatUrlForLaunching('www.example.com', LinkType.webUrl),
          'https://www.example.com',
        );
      });

      test('should not modify web URLs that already have protocol', () {
        expect(
          LinkDetector.formatUrlForLaunching('https://example.com', LinkType.webUrl),
          'https://example.com',
        );
        expect(
          LinkDetector.formatUrlForLaunching('http://example.com', LinkType.webUrl),
          'http://example.com',
        );
      });

      test('should handle file URLs correctly', () {
        expect(
          LinkDetector.formatUrlForLaunching('/path/to/file.pdf', LinkType.pdfFile),
          '/path/to/file.pdf',
        );
        expect(
          LinkDetector.formatUrlForLaunching('www.example.com/file.pdf', LinkType.pdfFile),
          'https://www.example.com/file.pdf',
        );
      });
    });

    group('isValidLink', () {
      test('should validate web URLs correctly', () {
        expect(LinkDetector.isValidLink('https://example.com', LinkType.webUrl), true);
        expect(LinkDetector.isValidLink('www.example.com', LinkType.webUrl), true);
        expect(LinkDetector.isValidLink('example.com', LinkType.webUrl), true);
        expect(LinkDetector.isValidLink('not-a-url', LinkType.webUrl), false);
      });

      test('should validate PDF files correctly', () {
        expect(LinkDetector.isValidLink('document.pdf', LinkType.pdfFile), true);
        expect(LinkDetector.isValidLink('/path/to/file.pdf', LinkType.pdfFile), true);
        expect(LinkDetector.isValidLink('https://example.com/file.pdf', LinkType.pdfFile), true);
        expect(LinkDetector.isValidLink('not-a-pdf.txt', LinkType.pdfFile), false);
      });

      test('should validate document files correctly', () {
        expect(LinkDetector.isValidLink('document.doc', LinkType.documentFile), true);
        expect(LinkDetector.isValidLink('file.docx', LinkType.documentFile), true);
        expect(LinkDetector.isValidLink('readme.txt', LinkType.documentFile), true);
        expect(LinkDetector.isValidLink('notes.rtf', LinkType.documentFile), true);
        expect(LinkDetector.isValidLink('not-a-doc.pdf', LinkType.documentFile), false);
      });
    });
  });
}