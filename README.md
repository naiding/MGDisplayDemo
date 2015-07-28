#iOS系统相簿的实现(点击放大&拖拽&旋转)


![img](http://ww3.sinaimg.cn/bmiddle/e63be354jw1euiunj6c8sg208u0fqhdt.gif)

<br>

####需求：
<font size=2>iOS系统相簿的图片点击后可以放大显示，这在显示头像等照片上很常见；同时，系统相簿照片放大后可以进行旋转和继续拉大缩小，这对于用户观察照片细节有帮助，增强用户体验。</font>

<br>


####使用：
<font size=2>自定义了一个继承于NSObject类，实例化该类，在点击图片时调用以下方法即可：</font>

<p><pre>
<code>- (void)showImageView:(UIImageView *)imageView;</code>
</pre></p>

<br>
<br>

##一、单击放大和隐藏


<br><font size=3>1. 考虑到照片的展示应位于界面的最顶层，所以采用一个UIWindow, 在UIWindow上添加一个UIView来展示照片。</font>
<p><pre>
<code>@property (strong, nonatomic) UIWindow *thisWindow;
@property (strong, nonatomic) UIView *thisView;
@property (strong, nonatomic) UIImageView *thisImageView;</code>
</pre></p>

<br><font size=3>2. 在点击屏幕时窗口消失，添加Tap手势。</font>
<p><pre>
<code>@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;</code>
</pre></p>

<br><font size=3>3. 窗口消失时回到原图片位置，需存储原图片的位置和大小。</font>
<p><pre>
<code>@property (assign, nonatomic) CGRect oldFrame;
@property (strong, nonatomic) UIImage *displayImage;</code>
</pre></p>

<br><font size=3>4. 方法实现</font>
<p><pre>
<code>- (void)showImageView:(UIImageView *)imageView
{
	//获取所要展示图片
    self.displayImage = imageView.image; 
    //得到当前窗口
    self.thisWindow = [UIApplication sharedApplication].keyWindow; 
    //设置全屏View大小
    self.thisView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height); 
    // 一些配置 
    self.thisView.backgroundColor = [UIColor blackColor]; 
    self.thisView.alpha = 0;
    
    //获取imageView的位置大小
    self.oldFrame = [imageView convertRect:imageView.bounds toView:self.thisWindow]; 
	
    self.thisImageView.frame = self.oldFrame;
    self.thisImageView.image = self.displayImage;
    
    [self.thisView addSubview:self.thisImageView];
    [self.thisWindow addSubview:self.thisView];
    
    [self.thisView addGestureRecognizer:self.tapGestureRecognizer];
    
    //对要展示的图片进行动画放大
    [UIView animateWithDuration:0.3 animations:^{
        self.thisImageView.frame = CGRectMake(0,
        ([UIScreen mainScreen].bounds.size.height - self.displayImage.size.height * [UIScreen mainScreen].bounds.size.width / self.displayImage.size.width) / 2, 
        [UIScreen mainScreen].bounds.size.width, 
        self.displayImage.size.height * [UIScreen mainScreen].bounds.size.width / self.displayImage.size.width);
        self.thisView.alpha = 1;
    } completion:^(BOOL finished) {}];
}</code>
</pre></p>

<p><pre>
<code>- (void)hideImage:(UITapGestureRecognizer *) tapGesture{
    
    // 动画消失
    [UIView animateWithDuration:0.3 animations:^{
        self.thisImageView.frame = self.oldFrame;
        self.thisView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.thisView removeFromSuperview];
        self.thisImageView.frame = CGRectZero;
        self.thisImageView.transform = CGAffineTransformIdentity;
    }];
}</code>
</pre></p>


<br>
<br>
<br>

##二、组合 Pinch & Rotate & Pan Gesture (重点)


<br><font size=3>1. 三个手势：Pinch, Rotation, Pan.</font>
<p><pre>
<code>@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (strong, nonatomic) UIRotationGestureRecognizer *rotationGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;</code>
</pre></p>

<br><font size=3>2. 用一个集合来存储所有正在进行的手势：这里的思路是将正在进行的手势装入集合，然后统一进行处理（对仿射变换进行多次叠加）后，依次还原效果。</font>
<p><pre>
<code>@property (strong, nonatomic) NSMutableSet *activeRecognizers;</code>
</pre></p>

<br><font size=3>3. 一个临时的仿射变换，便于计算叠加变换</font>
<p><pre>
<code>@property (assign, nonatomic) CGAffineTransform referenceTransform;</code>
</pre></p>

<br><font size=3>4. UIGestureRecognizer的一个代理方法，这个方法必须实现：返回YES，允许同时处理多个手势。</font>
<p><pre>
<code>#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
- {
    return YES;
}</code>
</pre></p>

<br><font size=3>5. Gesture的方法：三个Gesture均响应该方法。</font>
<p><pre>
<code>- (void)handleGesture:(UIGestureRecognizer *)paramSender
{
    switch (paramSender.state) {
            
        //有Gesture开始
        case UIGestureRecognizerStateBegan:{
        	
        	//如果当前手势集合里没有手势，则将当前imageView的仿射变换存储referenceTransform
            if (self.activeRecognizers.count == 0)
                self.referenceTransform = self.thisImageView.transform;
                
            //将当前手势加入集合
            [self.activeRecognizers addObject:paramSender];
            break;
        }
            
        //Gesture变化
        case UIGestureRecognizerStateChanged: {
        
        	//获取上一次记录的referenceTransform
            CGAffineTransform transform = self.referenceTransform;
            
            //对集合里每一个手势的仿射变换进行叠加
            for (UIGestureRecognizer *recognizer in self.activeRecognizers){
                transform = [self applyRecognizer:recognizer toTransform:transform];
            }
            
            //将最终的计算的仿射变换赋给imageView
            self.thisImageView.transform = transform;
            
            break;
        }
            
            
        //变换结束后，将imageView恢复原位
        case UIGestureRecognizerStateEnded: {
            self.referenceTransform = [self applyRecognizer:paramSender toTransform:self.referenceTransform];
            
            //从集合中移除当前手势
            [self.activeRecognizers removeObject:paramSender];
            
            
            //将imageView放置到最初状态，这个UIView的变换在showImage:出现过。
            [UIView animateWithDuration:0.3 animations:^{
            
            	//将仿射变换"归零"
                self.thisImageView.transform = CGAffineTransformIdentity;
                
                //imageView"归位"
                self.thisImageView.frame = CGRectMake(0,([UIScreen mainScreen].bounds.size.height-self.displayImage.size.height * [UIScreen mainScreen].bounds.size.width/self.displayImage.size.width)/2, [UIScreen mainScreen].bounds.size.width, self.displayImage.size.height*[UIScreen mainScreen].bounds.size.width/self.displayImage.size.width);
            } completion:^(BOOL finished) {}];
            
            break;
        }
        default:
            break;
    }
}</code>
</pre></p>




<br><font size=3>6. UIGestureRecognizerStateChanged中调用的处理方法</font>
<p><pre>
<code>- (CGAffineTransform)applyRecognizer:(UIGestureRecognizer *)recognizer toTransform:(CGAffineTransform)transform
{

	//返回Rotation手势的响应的旋转仿射变换（这个包括下面的变换都是基于上一个transform的）
    if ([recognizer respondsToSelector:@selector(rotation)])    
        return CGAffineTransformRotate(transform,
         [(UIRotationGestureRecognizer *)recognizer rotation]);  
        
    //返回Pinch手势的响应的旋转仿射变换  
    else if ([recognizer respondsToSelector:@selector(scale)]) {
        CGFloat scale = [(UIPinchGestureRecognizer *)recognizer scale];
        return CGAffineTransformScale(transform, scale, scale);
    }
    
    //返回Pan手势的响应的旋转仿射变换  
    else {
        return CGAffineTransformTranslate(transform,
        [(UIPanGestureRecognizer *)recognizer translationInView:self.thisView].x, 
        [(UIPanGestureRecognizer *)recognizer translationInView:self.thisView].y);
    }
    return transform;
}</code>
</pre></p>


###具体的类成员以及方法实现上述均有说明或者注释
###工程代码在[这里](https://github.com/zhounaiding/MGDisplayDemo.git "Title").

