# MSFloatingViewManager
This is super simple module that you can control your headerView floated.

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

1. floatingDistance

2. enableFloatingViewAnimation

3. alphaEffectWhenHidding

![](https://i.imgflip.com/og53f.jpg)
