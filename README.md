# MSFloatingViewManager
This is super simple module that you can control your headerView floated.

![](https://github.com/ahimahas/MSFloatingViewManager/blob/master/Images/example.gif?raw=true)


# How to Get Started
The only thing your need is initialize MSFloatingViewManager and that's all.

```
  @property(nonatomic, strong) MSFloatingViewManager *floatingViewManager;

  ...
  // in somewhere usually in 'viewDidLoad'
  _floatingViewManager = [[MSFloatingViewManager alloc] initWithCallingObject:self scrollView:scrollView headerView:headerView];
  ...
```

# Options
There are 3 options.

1. floatingDistance<br>
You can set move distance of floating view (which is headerView). Default value is headerView's height.
For example, if you set this value like below, headerView move only half distance of it's height.
```
  [_floatingViewManager setFloatingDistance:CGRectGetHeight(_headerView.frame) / 2];
```<br>
2. enableFloatingViewAnimation<br>
You can control floatingView action with this value. Default value is YES.
If you set this value as NO, floating animation doesn't work.<br>
3. alphaEffectWhenHidding<br>
You can give alpha effect to headerView and its' all subviews. Default Value is NO.



