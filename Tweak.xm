#import <substrate.h>

//LLAdditions
@interface MFMutableMessageHeaders
+ (id)alloc;
- (id)init;
- (void)setHeader:(id)header forKey:(id)key;
- (void)setAddressList:(id)list forKey:(id)key;
- (void)setAddressListForTo:(id)arg1;
- (void)setAddressListForSender:(id)arg1;
@end

@interface MFMessageWriter
-(id)createMessageWithString:(id)string headers:(id)headers;
@end

@interface MFMailDelivery
+ (id)newWithMessage:(id)arg1;
- (void)setDelegate:(id)arg1;
- (int)deliverSynchronously;
- (void)deliverAsynchronously;
@end

@interface MFOutgoingMessage
@end

static id <UITableViewDataSource> theDataSource;
static id <UITableViewDelegate> theDelegate;
static BOOL on = NO;

#import <MessageUI/MessageUI.h>

%hook SBLockScreenNotificationTableView

- (void)setDelegate:(id)orgDlg
{
  %orig;
  theDelegate = orgDlg;
  // NSLog(@"xl_SBLockScreenNotificationTableView_setDelegate: %@", orgDlg);
}

- (void)setDataSource:(id)orgDS
{
  %orig;
  theDataSource = orgDS;

  // NSLog(@"xl_SBLockScreenNotificationTableView_setDataSource: %@", orgDS);
}

- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  %orig;

  static NSMutableArray<NSString *> *ignoreKeywords;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      ignoreKeywords = [NSMutableArray new];
      [ignoreKeywords addObject:@"iPhone未读消息"];
      [ignoreKeywords addObject:@"QQ邮箱提醒"];
  });

  // NSLog(@"xl_SBLockScreenNotificationTableView_insertRowsAtIndexPaths: %@", indexPaths);

  NSIndexPath *xl_indexPath = [indexPaths firstObject];
  id xl_cell = [theDataSource tableView:(UITableView *)self cellForRowAtIndexPath:xl_indexPath];
  if ([xl_cell isKindOfClass:NSClassFromString(@"SBLockScreenBulletinCell")])
  {
    NSArray *xl_cellSubviews = [xl_cell subviews];
    for (NSInteger i = 0; i < [xl_cellSubviews count]; ++i)
    {
      if ([xl_cellSubviews[i] isKindOfClass:NSClassFromString(@"SBLockScreenNotificationScrollView")])
      {
        UIScrollView *xl_nsview = xl_cellSubviews[i];
        UIView *xl_contentView = [[xl_nsview subviews] firstObject];

        // NSLog(@"xl_contentView: %@", xl_contentView);

        NSString *xl_sender = @"";
        NSString *xl_message = @"";
        NSString *xl_relativeDate = @"";
        NSInteger xl_contentCount = [[xl_contentView subviews] count];
        if (xl_contentCount >= 1)
        {
          id xl_senderLabel = [xl_contentView subviews][0];
          if ([xl_senderLabel isKindOfClass:[UILabel class]])
          {
            xl_sender = [(UILabel *)xl_senderLabel text];
            NSLog(@"xl_sender: %@", xl_sender);
          }
        }
        for (NSInteger xl_index = 1; xl_index < xl_contentCount; ++xl_index)
        {
          id xl_subview = [xl_contentView subviews][xl_index];
          if ([xl_subview isKindOfClass:NSClassFromString(@"SBRelativeDateLabel")])
          {
            xl_relativeDate = [(UILabel *)xl_subview text];
            NSLog(@"xl_relativeDate: %@", xl_relativeDate);
          }
          else
          {
            if ([xl_subview isKindOfClass:[UILabel class]])
            {
              NSString *xl_text = [(UILabel *)xl_subview text];
              NSLog(@"xl_subview: %@", xl_text);
              if (![xl_text isEqualToString: @"滑动来查看"])
              {
                xl_message = xl_text;
                NSLog(@"xl_message: %@", xl_message);

                if ([xl_message containsString:@"静默穿山甲"])
                {
                  on = NO;
                  NSLog(@"自动发送已关闭");
                }
                else if ([xl_message containsString:@"穿山甲不爱吃["])
                {
                  NSRange range = [xl_message rangeOfString:@"穿山甲不爱吃["];
                  if (range.location != NSNotFound)
                  {
                      NSString *keyword = [xl_message substringFromIndex:range.location+range.length];
                      NSRange endRange = [keyword rangeOfString:@"]"];
                      keyword =[keyword substringToIndex:endRange.location];
                      [ignoreKeywords addObject:keyword];

                      NSLog(@"添加ignoreKeyword: %@", keyword);
                  }
                }
                else if ([xl_message containsString:@"穿山甲爱吃["])
                {
                  NSRange range = [xl_message rangeOfString:@"穿山甲爱吃["];
                  if (range.location != NSNotFound)
                  {
                      NSString *keyword = [xl_message substringFromIndex:range.location+range.length];
                      NSRange endRange = [keyword rangeOfString:@"]"];
                      keyword =[keyword substringToIndex:endRange.location];
                      [ignoreKeywords removeObject:keyword];

                      NSLog(@"移除ignoreKeyword: %@", keyword);
                  }
                }
              }
            }
          }
        }
        if (on)
        {
          BOOL shouldIgnore = NO;
          for (NSString* ignoreKeyword in ignoreKeywords)
          {
              if ([xl_message containsString:ignoreKeyword])
              {
                  shouldIgnore = YES;
                  NSLog(@"消息内容包含关键字：%@, 忽略。", ignoreKeyword);
                  break;
              }
          }
          if (! shouldIgnore)
          {
            static NSString *xl_subject = @"iPhone未读消息";
            static NSString *xl_mailTo = @"1019158142@qq.com";
            static NSString *xl_mailBy = @"杨 鑫磊 <yangxinlei007@live.com>";
            if ([xl_relativeDate isEqualToString:@"现在"])
            {
              NSLog(@"发现未读消息，发送邮件: %@。", xl_mailTo);
              MFMessageWriter *messageWriter = [[%c(MFMessageWriter) alloc] init];
              MFMutableMessageHeaders *headers = [[%c(MFMutableMessageHeaders) alloc] init];
              [headers setHeader:xl_subject forKey:@"subject"];
              [headers setAddressListForTo:@[xl_mailTo]];
              [headers setAddressListForSender:@[xl_mailBy]];

              MFOutgoingMessage *message = [messageWriter createMessageWithString:[NSString stringWithFormat:@"消息源:%@\n内容:%@", xl_sender, xl_message] headers:headers];
              MFMailDelivery *messageDelivery = [%c(MFMailDelivery) newWithMessage:message];

              // [messageDelivery setDelegate:self];
              [messageDelivery deliverAsynchronously];
            }
          }

        }
        else
        {
          NSLog(@"功能处于关闭状态，不发送邮件。");
        }

        if ([xl_message containsString:@"代号穿山甲"])
        {
          on = YES;
          NSLog(@"自动发送启动");
        }
      }
    }
  }
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
  %orig;

  NSLog(@"xl_SBLockScreenNotificationTableView_insertSections: %@", sections);
}
// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
