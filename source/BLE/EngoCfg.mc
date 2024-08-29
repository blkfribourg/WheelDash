function arrayToRawCmd(str_bytes) {
  return Toybox.StringUtil.convertEncodedString(str_bytes, {
    :fromRepresentation => Toybox.StringUtil.REPRESENTATION_STRING_HEX,
    :toRepresentation => Toybox.StringUtil.REPRESENTATION_BYTE_ARRAY,
  });
}
