# ``JPEG.Data.Spectral``

## Topics

### Creating an image

-   ``init(size:layout:metadata:quanta:)``
-   ``decompress(stream:)``
-   ``decompress(path:)``


### Saving an image

-   ``compress(stream:)``
-   ``compress(path:)``


### Querying an image

-   ``size``
-   ``blocks``
-   ``layout``
-   ``metadata``
-   ``quanta``


### Editing an image

-   ``set(width:)``
-   ``set(height:)``
-   ``set(quanta:)``


### Changing representations

-   ``idct``
-   ``encode``


### Accessing planes

-   ``startIndex``
-   ``endIndex``
-   ``subscript(_:)``
-   ``index(forKey:)``
-   ``read(ci:_:)``
-   ``with(ci:_:)``
