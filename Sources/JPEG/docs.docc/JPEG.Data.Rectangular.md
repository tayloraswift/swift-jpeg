# ``JPEG.Data.Rectangular``

## Topics

### Creating an image

-   ``init(size:layout:metadata:values:)``
-   ``init(size:layout:metadata:)``
-   ``pack(size:layout:metadata:pixels:)``
-   ``decompress(stream:cosite:)``
-   ``decompress(path:cosite:)``


### Saving an image

-   ``compress(stream:quanta:)``
-   ``compress(path:quanta:)``


### Querying an image

-   ``size``
-   ``layout``
-   ``metadata``


### Changing representations

-   ``unpack(as:)``
-   ``decomposed``


### Accessing samples

-   ``stride``
-   ``subscript(x:y:p:)``
-   ``offset(forKey:)``
