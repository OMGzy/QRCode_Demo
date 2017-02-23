//
//  ViewController.m
//  QRCode_Demo
//
//  Created by Wang_zY on 2017/2/17.
//  Copyright © 2017年 Wang_zY. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView; // 用于显示二维码

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.imageView];
    
    // 创建二维码
    UIImage *qrcodeImage = [self creatQRcode];
    
    
    // 显示生成的二维码
    self.imageView.image = qrcodeImage;
    
}

- (UIImage *)creatQRcode
{
    // 二维码过滤器
    CIFilter *qrcodeFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 设置默认属性
    [qrcodeFilter setDefaults];
    // 二维码 内容
    NSString *contentStr = @"http://app.joyingnet.com/dl.php";
    NSData *qrcodeData = [contentStr dataUsingEncoding:NSUTF8StringEncoding];
    //我们可以打印,看过滤器的 输入属性.这样我们才知道给谁赋值
    NSLog(@"%@",qrcodeFilter.inputKeys);
    /*
     打印结果:
     inputMessage,        // 二维码内容
     inputCorrectionLevel // 二维码错误的等级,就是容错率
     
     inputCorrectionLevel对应logo最大尺寸(logo与二维码的百分比)
     L -----> 20%
     M -----> 27%
     Q -----> 35%
     H -----> 42%
     */
    // 通过KVO设置其属性
    [qrcodeFilter setValue:qrcodeData forKey:@"inputMessage"];
    [qrcodeFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    // 生成二维码
    CIImage *qrcodeImage = [qrcodeFilter outputImage];
    // 打印CIImage的extent 会发现很小 其是根据输入消息的大小(字符的多少)决定 并影响二维码的密度
    NSLog(@"放大前:QRCodeImageSize:%@",qrcodeImage.description);
    // 放大图片
    // 第一种方案: 直接整体放大固定倍数
//    qrcodeImage = [qrcodeImage imageByApplyingTransform:CGAffineTransformMakeScale(7, 7)];
    // 第二种方案: 根据ImageView大小将位图(bitmap)放大相应倍数
    // (1) 获取CIImage的extent
    CGRect extent = CGRectIntegral(qrcodeImage.extent);
    // (2) 计算相应倍数(根据ImageView的宽高)
    CGFloat size = CGRectGetWidth(self.imageView.bounds);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // (3) 创建bitmap
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray(); // 创建一个DeviceGray颜色空间
    /*
     data                指向要渲染的绘制内存的地址。这个内存块的大小至少是（bytesPerRow*height）个字节
     width               bitmap的宽度,单位为像素
     height              bitmap的高度,单位为像素
     bitsPerComponent    内存中像素的每个组件的位数.例如，对于32位像素格式和RGB 颜色空间，你应该将这个值设为8.
     bytesPerRow         bitmap的每一行在内存所占的比特数
     colorspace          bitmap上下文使用的颜色空间。
     bitmapInfo          指定bitmap是否包含alpha通道，像素中alpha通道的相对位置，像素组件是整形还是浮点型等信息的字符串。
     */
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, width * 4, colorSpaceRef, (CGBitmapInfo)kCGImageAlphaNone);
    // (4) 设置对上下文的操作
    CIContext *context = [CIContext contextWithOptions:nil];
    // (5) 创建CoreGraphics image
    CGImageRef bitmapImageRef = [context createCGImage:qrcodeImage fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImageRef);
    // (6) 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    // (7) 释放CG对象
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImageRef);
    
    // 第一种方案得到的图片
//    UIImage *transitionImage = [UIImage imageWithCIImage:qrcodeImage];
    // 第二种方案得到的图片
    UIImage *transitionImage = [UIImage imageWithCGImage:scaledImage];
    NSLog(@"放大后:QRCodeImageSize:%@",transitionImage.description);
    
    /*
//================================== 改变颜色 =====================================
    transitionImage = [self imageBlackToTransparent:transitionImage withRed:100.0 andGreen:167.f andBlue:208.f];
//================================== 改变颜色 =====================================
    
//================================== 添加logo =====================================
    // 1.开始绘制图片上下文
    UIGraphicsBeginImageContextWithOptions(transitionImage.size, NO, [[UIScreen mainScreen] scale]);
    // 2.设置图片绘制区域
    [transitionImage drawInRect:CGRectMake(0, 0, size, size)];
    // 3.拿到logo
    UIImage *logoImage = [UIImage imageNamed:@"heihei.jpeg"];
    // 4.把logo图画到生成的二维码图片上，注意尺寸不要太大（最大不超过二维码图片的%30），太大会造成扫不出来
    // 计算出logo要显示出的大小
    CGFloat logoSize = size * 0.2;
    [logoImage drawInRect:CGRectMake(size - logoSize - 6, size - logoSize - 6, logoSize, logoSize)];
    // 5.获取包含当前所有文的图片
    UIImage *logoQRCodeImage = UIGraphicsGetImageFromCurrentImageContext();
    // 6.结束绘制
    UIGraphicsEndImageContext();
    
//================================== 添加logo =====================================
     
     */
    
    return transitionImage;
}

- (UIImage*)imageBlackToTransparent:(UIImage*)image withRed:(CGFloat)red andGreen:(CGFloat)green andBlue:(CGFloat)blue{
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage); // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900) // 将白色变成透明
        {
            // 改成下面的代码，会将图片转成想要的颜色
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
        } else {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    // 输出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, nil);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef]; // 清理空间
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 9200)];
        _imageView.center = self.view.center;
//        _imageView.backgroundColor = [UIColor redColor];
    }
    return _imageView;
}


@end
