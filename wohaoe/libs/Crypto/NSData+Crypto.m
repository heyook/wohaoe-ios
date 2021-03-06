// Crypto categories for iOS

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

#import "NSData+Crypto.h"
#import "NSString+Crypto.h"


// --------
@implementation NSData( Crypto )

- (NSData *) aesEncryptedDataWithKey:(NSData *) key {
  unsigned char               *buffer = nil;
  size_t                      bufferSize;
  CCCryptorStatus             err;
  NSUInteger                  i, keyLength, plainTextLength;
  
  // make sure there's data to encrypt
  err = ( plainTextLength = [self length] ) == 0;
  
  // pass the user's passphrase through SHA256 to obtain 32 bytes
  // of key data.  Use all 32 bytes for an AES256 key or just the
  // first 16 for AES128.
  if ( ! err ) {
    switch ( ( keyLength = [key length] ) ) {
      case kCCKeySizeAES128:
      case kCCKeySizeAES256:                      break;
        
        // invalid key size
      default:                    err = 1;        break;
    }
  }
  
  // create an output buffer with room for pad bytes
  if ( ! err ) {
    bufferSize = kCCBlockSizeAES128 + plainTextLength + kCCBlockSizeAES128;     // iv + cipher + padding
    
    err = ! ( buffer = (unsigned char *) malloc( bufferSize ) );
  }
  
  // encrypt the data
  if ( ! err ) {
    srandomdev();
    
    // generate a random iv and prepend it to the output buffer.  the
    // decryptor needs to be aware of this.
    for ( i = 0; i < kCCBlockSizeAES128; ++i ) buffer[ i ] = random() & 0xff;
    
    err = CCCrypt( kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                  [key bytes], keyLength, buffer, [self bytes], plainTextLength,
                  buffer + kCCBlockSizeAES128, bufferSize - kCCBlockSizeAES128, &bufferSize );
  }
  
  if ( err ) {
    if ( buffer ) free( buffer );
    
    return nil;
  }
  
  // dataWithBytesNoCopy takes ownership of buffer and will free() it
  // when the NSData object that owns it is released.
  return [NSData dataWithBytesNoCopy: buffer length: bufferSize + kCCBlockSizeAES128];
}

- (NSString *) base64Encoding {
  char                    *encoded, *r;
  const char              eTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  unsigned                i, l, n, t;
  UInt8                   *p, pad = '=';
  NSString                *result;
  
  p = (UInt8 *) [self bytes];
  if ( ! p || ( l = [self length] ) == 0 ) return @"";
  r = encoded = malloc( 4 * ( ( n = l / 3 ) + ( l % 3 ? 1 : 0 ) ) + 1 );
  
  if ( ! encoded ) return nil;
  
  for ( i = 0; i < n; ++i ) {
    t  = *p++ << 16;
    t |= *p++ << 8;
    t |= *p++;
    
    *r++ = eTable[ t >> 18 ];
    *r++ = eTable[ t >> 12 & 0x3f ];
    *r++ = eTable[ t >>  6 & 0x3f ];
    *r++ = eTable[ t       & 0x3f ];
  }
  
  if ( ( i = n * 3 ) < l ) {
    t = *p++ << 16;
    
    *r++ = eTable[ t >> 18 ];
    
    if ( ++i < l ) {
      t |= *p++ << 8;
      
      *r++ = eTable[ t >> 12 & 0x3f ];
      *r++ = eTable[ t >>  6 & 0x3f ];
    } else {
      *r++ = eTable[ t >> 12 & 0x3f ];
      *r++ = pad;
    }
    
    *r++ = pad;
  }
  
  *r = 0;
  
  result = [NSString stringWithUTF8String: encoded];
  
  free( encoded );
  
  return result;
}

@end



// -----------------

//
//@implementation AppDelegate
//
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
//  NSData              *plain = [@"This is a test of the emergency broadcast system." dataUsingEncoding: NSUTF8StringEncoding];
//  NSData              *key = [NSData dataWithBytes: [[@"Salamander" sha256] bytes] length: kCCKeySizeAES128];
//  NSData              *cipher = [plain aesEncryptedDataWithKey: key];
//  NSString            *base64 = [cipher base64Encoding];
//  
//  NSLog( @"cipher: %@", base64 );
//  
//  // stuff the base64'ed cipher into decrypt.php:
//  // http://localhost/~par/decrypt.php?cipher=<base64_output>
//  
//  /*
//   <?php
//   header( "content-type: text/plain" );
//   
//   if ( ! ( $cipher = $_GET[ 'cipher' ] ) ) {
//   echo "no cipher parameter found";
//   return;
//   }
//   
//   echo "cipher: $cipher\n";
//   
//   $cipher = base64_decode( $cipher );
//   $iv = substr( $cipher, 0, 16 );
//   $cipher = substr( $cipher, 16 );
//   
//   // use the full key (all 32 bytes) for aes256
//   $key = substr( hash( "sha256", "Salamander", true ), 0, 16 );
//   
//   $plainText = mcrypt_decrypt( MCRYPT_RIJNDAEL_128, $key, $cipher, MCRYPT_MODE_CBC, $iv );
//   $plainTextLength = strlen( $plainText );
//   
//   // strip pkcs7 padding
//   $padding = ord( $plainText[ $plainTextLength - 1 ] );
//   $plainText = substr( $plainText, 0, -$padding );
//   
//   printf( "plaintext: %s\n", $plainText );
//   ?>
//   */
//  
//  return YES;
//}

//@end