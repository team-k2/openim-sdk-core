# OpenIM SDK Core - Message Edit API Reference

## Overview

This document describes the message editing functionality implemented in OpenIM SDK Core v3.

## API Functions

### 1. EditMessage

Edit an existing message.

```go
func (c *Conversation) EditMessage(ctx context.Context, conversationID string, seq int64, newContent, editReason string) error
```

**Parameters:**
- `conversationID` - Conversation identifier
- `seq` - Message sequence number
- `newContent` - New message content
- `editReason` - Reason for editing (optional)

**Returns:**
- `error` - nil on success, error otherwise

**Business Rules:**
- Messages can only be edited within 24 hours
- Only message sender can edit (except group admins)
- Maximum 3 edits per message

### 2. ValidateEditPermission

Check if user has permission to edit a message.

```go
func (c *Conversation) ValidateEditPermission(ctx context.Context, conversationID string, seq int64) (bool, string, error)
```

**Returns:**
- `canEdit` - Whether editing is allowed
- `reason` - Reason if not allowed
- `error` - System error if any

### 3. GetMessageEditHistory

Retrieve edit history for a message.

```go
func (c *Conversation) GetMessageEditHistory(ctx context.Context, conversationID string, seq int64) (string, error)
```

**Returns:**
- JSON string containing edit history array
- Error if retrieval fails

### 4. GetEditableMessages

Get list of messages that can be edited.

```go
func (c *Conversation) GetEditableMessages(ctx context.Context, conversationID string, pageNumber, showNumber int32) (string, error)
```

**Parameters:**
- `pageNumber` - Page number (1-based)
- `showNumber` - Messages per page

**Returns:**
- JSON string with paginated results
- Error if query fails

## Export Functions (FFI)

These functions are exported for FFI bindings:

```go
// open_im_sdk/conversation_msg.go

func EditMessage(callback open_im_sdk_callback.Base, operationID string, conversationID string, seq int64, newContent string, editReason string)

func ValidateEditPermission(callback open_im_sdk_callback.Base, operationID string, conversationID string, seq int64)

func GetMessageEditHistory(callback open_im_sdk_callback.Base, operationID string, conversationID string, seq int64)

func GetEditableMessages(callback open_im_sdk_callback.Base, operationID string, conversationID string, pageNumber int32, showNumber int32)
```

## Protocol Buffers

Located at: `pkg/proto/msg_edit/msg_edit.proto`

Key message types:
- `EditMessageReq`
- `EditMessageResp`
- `ValidateEditPermissionReq`
- `ValidateEditPermissionResp`
- `GetMessageEditHistoryReq`
- `GetMessageEditHistoryResp`
- `GetEditableMessagesReq`
- `GetEditableMessagesResp`

## Implementation Files

| File | Purpose |
|------|---------|
| `internal/conversation_msg/edit.go` | Core business logic |
| `internal/conversation_msg/server_api.go` | Server API calls |
| `internal/conversation_msg/api.go` | Public API methods |
| `open_im_sdk/conversation_msg.go` | FFI export layer |

## Error Handling

Common error scenarios:
- `ErrNoPermission` - User lacks edit permission
- `ErrTimeExpired` - 24-hour edit window expired
- `ErrEditLimitExceeded` - Maximum edit count reached
- `ErrMessageNotFound` - Message doesn't exist

## Testing

Test files:
- Unit tests: `internal/conversation_msg/edit_test.go` (to be created)
- Integration tests: See Flutter SDK tests

## Version History

- v1.0.0 (2024-11-01) - Initial implementation