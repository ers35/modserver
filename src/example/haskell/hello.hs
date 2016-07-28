{-# LANGUAGE ForeignFunctionInterface #-}

module Hello where

import Foreign
import Foreign.C.String
import Foreign.C.Types

foreign import ccall "modserver.h rwrite" rwrite :: Ptr () -> CString -> CInt -> IO CInt
foreign export ccall run :: Ptr () -> IO CInt

run :: Ptr () -> IO CInt
run s = do
  reply <- newCString "hello from Haskell"
  rwrite s reply 18
  free reply
  return 0
