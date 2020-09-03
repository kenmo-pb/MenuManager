# MenuManager for PureBasic

A library for handling dynamic menus and customizable shortcuts


## About

This PureBasic library helps you manage menus and keyboard shortcuts, with these goals:

1. Reduce the code needed to build menus, assign shortcuts, and change them
2. Add functionality not available in the built-in libraries
3. Minimize the cross-platform differences you have to handle


The main feature is that menus and shortcuts can be defined in a text file, then built automatically.

It's as simple as:

    IncludeFile "MenuManager.pbi"
    
    LoadMenuManager(File$)
    BuildManagedMenu(MenuNumber, Window, MenuID$)


## Documentation

Documentation is next on the to-do list!

For now, check out the [examples](./examples/) folder.


## Credits

MenuManager is by *kenmo-pb*.

Unless you disable the XML frontend (`#MenuManager_UseXMLParser = #False`), MenuManager uses the Expat XML Library and Expat's license must be included with your released software.
