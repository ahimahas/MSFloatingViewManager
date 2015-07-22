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

1. floatingDistance<br>
  ![](https://github.com/ahimahas/MSFloatingViewManager/blob/master/Images/halfDistance.gif?raw=true)
2. enableFloatingViewAnimation

3. alphaEffectWhenHidding



