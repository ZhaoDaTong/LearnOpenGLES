//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by loyinglin on 16/3/11.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import "LearnView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESUtils.h"
#import "GLESMath.h"

static CGFloat timeUpdate = 0.05;
static CGFloat degreeUpdate = 5;

@interface LearnView()
@property (nonatomic , strong) EAGLContext* myContext;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;
@property (nonatomic , assign) GLuint       myProgram;


@property (nonatomic , assign) GLuint myColorRenderBuffer;
@property (nonatomic , assign) GLuint myFrameRenderBuffer;
@property (nonatomic , assign) GLuint myDepthRenderBuffer;

- (void)setupLayer;

@end

@implementation LearnView
{
    float degree;
    float yDegree;
    BOOL bX;
    BOOL bY;
    NSTimer* myTimer;
    
    float saturation;
    
    GLint attrBuffer;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    attrBuffer = [self createBufferData];
    [self createProgram];
    
    [self render];
}

- (IBAction)onTimer:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:timeUpdate target:self selector:@selector(onRes:) userInfo:nil repeats:YES];
    }
    bX = !bX;
}

- (IBAction)onYTimer:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:timeUpdate target:self selector:@selector(onRes:) userInfo:nil repeats:YES];
    }
    bY = !bY;
}

- (IBAction)onSlider:(UISlider *)sender {
    float value = sender.value;
    saturation = value;
    [self render];
}

- (void)onRes:(id)sender {
    degree += bX * degreeUpdate;
    yDegree += bY * degreeUpdate;
    [self render];
}

- (void)createProgram {
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        // 获取program link 错误状态
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);

        return;
    }
    
    glUseProgram(self.myProgram);
}

- (GLint)createBufferData {
    CGFloat defaultPointValue = 0.3f;
    // 顶点及颜色数组
    GLfloat attrArr[] =
    {
        -defaultPointValue, defaultPointValue, 0.0f, 1.0f, 0.0f, 1.0f, //左上
        defaultPointValue, defaultPointValue, 0.0f, 1.0f, 0.0f, 1.0f, //右上
        -defaultPointValue, -defaultPointValue, 0.0f, 1.0f, 1.0f, 1.0f, //左下
        defaultPointValue, -defaultPointValue, 0.0f, 1.0f, 1.0f, 1.0f, //右下
        0.0f, 0.0f, -1.0f, 1.0f, 0.0f, 0.0f, //顶点
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    return attrBuffer;
}

- (void)render {
    glEnable(GL_DEPTH_TEST);
    
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    glEnableVertexAttribArray(positionColor);
    
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    GLuint fSaturation = glGetUniformLocation(self.myProgram, "saturation");
    
    
    glUniform1f(fSaturation, saturation);
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
    // Generate a perspective matrix with a 60 degree FOV

    // 初始化原始3D变换矩阵
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    
    ksTranslate(&_projectionMatrix, 0.3, 0.3, 0.0);
    // 根据显示大小更改原始矩阵
    float aspect = width / height;
    ksPerspective(&_projectionMatrix, 30.0, aspect, -25.0f, -20.0f); //透视变换
    
    // Load projection matrix，绑定原始矩阵数据到vertex program
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix);
    
    
    // 初始化变换3D变换矩阵
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    // 移动变换矩阵
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, 0.0);
    ksRotate(&_modelViewMatrix, degree, 1.0, 0.0, 0.0);
    ksRotate(&_modelViewMatrix, yDegree, 0.0, 1.0, 0.0);

    // Load the model-view matrix
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix);
    
    // 索引数组，三个点组成一个三角形
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    
    // Free up no longer needed shader resources
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}



- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.myContext = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为 color renderbuffer 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
    int width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glGenRenderbuffers(1, &buffer);
    self.myDepthRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myDepthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
}

- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myFrameRenderBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myFrameRenderBuffer);
    
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, self.myDepthRenderBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_myFrameRenderBuffer);
    self.myFrameRenderBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    glDeleteRenderbuffers(1, &_myDepthRenderBuffer);
    self.myDepthRenderBuffer = 0;
}

@end
