# ``JPEG.Data.Planar``

## Topics

### Creating an image

-   ``init(size:layout:metadata:initializingWith:)``
-   ``init(size:layout:metadata:)``
-   ``decompress(stream:)``
-   ``decompress(path:)``


### Saving an image

-   ``compress(stream:quanta:)``
-   ``compress(path:quanta:)``


### Querying an image

-   ``size``
-   ``layout``
-   ``metadata``


### Changing representations

-   ``interleaved(cosite:)``
-   ``fdct(quanta:)``


### Accessing planes

-   ``startIndex``
-   ``endIndex``
-   ``subscript(_:)``
-   ``index(forKey:)``
-   ``read(ci:_:)``
-   ``with(ci:_:)``
