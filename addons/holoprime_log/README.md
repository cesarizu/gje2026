# Holopri.me Log

Simple log utils.

# Setup

Copy the contents of `addons/holoprime_log` into your project, or use git:

```bash
git remote add holoprime_log https://gitlab.com/holopri.me/addons/holoprime_log.git
git fetch holoprime_log
git subtree add --prefix addons/holoprime_log --squash --message="Added Holopri.me Log addon" holoprime_log/split
```

And to update:

```bash
git fetch holoprime_log
git subtree merge --prefix addons/holoprime_log --squash --message="Updated Holopri.me Log addon" holoprime_log/split
```

# Usage

```python
Log.debug(&"SomeChannel", "Some log")
```

To enable or disable a channel use:

```python
Log.set_enabled(&"SomeChannel", Log.Level.WARNING, false)
print(Log.is_enabled(&"SomeChannel", Log.Level.WARNING)) // outputs false
```
