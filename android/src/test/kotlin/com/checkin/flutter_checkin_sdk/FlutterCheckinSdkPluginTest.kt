package com.checkin.flutter_checkin_sdk

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class FlutterCheckinSdkPluginTest {
    @Test
    fun onMethodCall_initialize_returnsSuccess() {
        val plugin = FlutterCheckinSdkPlugin()

        val call = MethodCall("initialize", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(null)
    }
}
